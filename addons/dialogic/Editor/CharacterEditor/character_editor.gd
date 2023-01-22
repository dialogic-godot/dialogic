@tool
extends DialogicEditor

## Editor for editing character resources.

signal character_loaded(resource_path:String)
signal portrait_selected()


# Enums
enum PreviewModes {Full, Real}

# Current state
var current_preview_mode = PreviewModes.Full
var loading = false
var current_previewed_scene = null

# References
var selected_item: TreeItem 

##############################################################################
##							RESOURCE LOGIC
##############################################################################

# Method is called once editors manager is ready to accept registers.
func _register() -> void:
	# Makes the editor open this when a .dch file is selected.
	# Then _open_resource() is called.
	editors_manager.register_resource_editor("dch", self)
	# Add an "add character" button
	var add_character_button = editors_manager.add_icon_button( 
			load("res://addons/dialogic/Editor/Images/Toolbar/add-character.svg"),
			'Add Character',
			self)
	add_character_button.pressed.connect(
			editors_manager.show_add_resource_dialog.bind(
			new_character, 
			'*.dch; DialogicCharacter',
			'Create new character',
			'character',
			))


# Called when a character is opened somehow
func _open_resource(resource:Resource) -> void:
	# update resource
	current_resource = (resource as DialogicCharacter)
	
	# make sure changes in the ui won't trigger saving
	loading = true
	
	## Load other main tabs
	for main_edit in %MainEditTabs.get_children():
		main_edit._load_character(current_resource)
	
	%DefaultPortraitPicker.set_value(resource.default_portrait)
	
	%MainScale.value = 100*resource.scale
	%MainOffsetX.value = resource.offset.x
	%MainOffsetY.value = resource.offset.y
	%MainMirror.button_pressed = resource.mirror
	
	# Portrait section
	%PortraitSearch.text = ""
	load_portrait_tree()
	
	loading = false
	character_loaded.emit(resource.resource_path)


func _save_resource() -> void:
	if ! visible or not current_resource:
		return
	
	# Portrait list
	current_resource.portraits = get_updated_portrait_dict()
	
	# Portrait settings
	if %DefaultPortraitPicker.current_value in current_resource.portraits.keys():
		current_resource.default_portrait = %DefaultPortraitPicker.current_value
	elif !current_resource.portraits.is_empty():
		current_resource.default_portrait = current_resource.portraits.keys()[0]
	else:
		current_resource.default_portrait = ""
	
	current_resource.scale = %MainScale.value/100.0
	current_resource.offset = Vector2(%MainOffsetX.value, %MainOffsetY.value) 
	current_resource.mirror = %MainMirror.button_pressed
	
	# Main tabs
	for main_edit in %MainEditTabs.get_children():
		current_resource = main_edit._save_changes(current_resource)
	
	ResourceSaver.save(current_resource, current_resource.resource_path)
	current_resource_state = ResourceStates.Saved
	editors_manager.resource_helper.rebuild_character_directory()


# Saves a new empty character to the given path
func new_character(path: String) -> void:
	var resource := DialogicCharacter.new()
	resource.resource_path = path
	resource.display_name = path.get_file().trim_suffix("."+path.get_extension())
	resource.color = Color(1,1,1,1)
	resource.default_portrait = ""
	resource.custom_info = {}
	ResourceSaver.save(resource, path)
	editors_manager.edit_resource(resource)


##############################################################################
##							INTERFACE
##############################################################################

func _ready() -> void:
	setup_portrait_list_tab()
	
	setup_portrait_settings_tab()
	
	%PreviewMode.item_selected.connect(_on_PreviewMode_item_selected)
	%PreviewMode.select(DialogicUtil.get_project_setting('dialogic/editor/character_preview_mode', 0))
	_on_PreviewMode_item_selected(%PreviewMode.selected)
	
	## General Styling
	var panel_style = DCSS.inline({
		'border-radius': 3,
		'border': 0,
		'border_color':get_theme_color("dark_color_3", "Editor"),
		'background': get_theme_color("base_color", "Editor"),
		'padding': [10, 10],
	})
	
	var tab_panel :StyleBoxFlat = get_theme_stylebox('tab_selected', 'TabContainer').duplicate()
	tab_panel.bg_color = get_theme_color("base_color", "Editor")
	
	%MainEditTabs.add_theme_stylebox_override('panel', panel_style)
	%MainEditTabs.add_theme_stylebox_override('tab_selected', tab_panel)
	%MainEditTabs.add_theme_constant_override('side_margin', 5)
	%PortraitListSection.add_theme_stylebox_override('panel', panel_style)
	%PortraitListSection.add_theme_stylebox_override('tab_selected', tab_panel)
	%PortraitListSection.add_theme_constant_override('side_margin', 5)
	%PortraitPreviewSection.add_theme_stylebox_override('panel', panel_style)
	%PortraitSettingsSection.add_theme_stylebox_override('panel', panel_style)
	%PortraitSettingsSection.add_theme_stylebox_override('tab_selected', tab_panel)
	%PortraitSettingsSection.add_theme_constant_override('side_margin', 5)
	
	%RealPreviewPivot.texture = get_theme_icon("EditorPivot", "EditorIcons")
	
	# Add general tab
	add_main_tab("res://addons/dialogic/Editor/CharacterEditor/character_editor_tab_general.tscn")
	
	# Load main tabs from subsystems/events
	for indexer in DialogicUtil.get_indexers():
		for main_tab in indexer._get_character_editor_tabs():
			add_main_tab(main_tab)
	
	for child in %PortraitSettingsSection.get_children():
		if !child is DialogicCharacterEditorPortraitSettingsTab:
			printerr("[Dialogic Editor] Portrait settings tabs should extend the right class!")
		else:
			child.character_editor = self
			child.changed.connect(something_changed)
			child.update_preview.connect(update_preview)


func add_main_tab(scene_path:String) ->  void:
	var edit: DialogicCharacterEditorMainTab =  load(scene_path).instantiate()
	edit.changed.connect(something_changed)
	edit.character_editor = self
	%MainEditTabs.add_child(edit)


func something_changed(fake_argument = "", fake_arg2 = null) -> void:
	if not loading:
		current_resource_state = ResourceStates.Unsaved
		editors_manager.save_current_resource() #TODO, should this happen?


##############################################################################
##							PORTRAIT SECTION
##############################################################################

func setup_portrait_list_tab() -> void:
	%PortraitTree.editor = self
	
	## Portrait section styling/connections
	%AddPortraitButton.icon = get_theme_icon("Add", "EditorIcons")
	%AddPortraitButton.pressed.connect(add_portrait)
	%AddPortraitGroupButton.icon = get_theme_icon("Groups", "EditorIcons")
	%AddPortraitGroupButton.pressed.connect(add_portrait_group)
	%ImportPortraitsButton.icon = get_theme_icon("Folder", "EditorIcons")
	%ImportPortraitsButton.pressed.connect(open_portrait_folder_select)
	%PortraitSearch.right_icon = get_theme_icon("Search", "EditorIcons")
	%PortraitSearch.text_changed.connect(filter_portrait_list)
	
	%PortraitTree.item_selected.connect(load_selected_portrait)
	%PortraitTree.item_edited.connect(_on_item_edited)

func open_portrait_folder_select() -> void:
	find_parent("EditorView").godot_file_dialog(
		import_portraits_from_folder, "*", 
		EditorFileDialog.FILE_MODE_OPEN_DIR)


func import_portraits_from_folder(path:String) -> void:
	var parent: TreeItem = %PortraitTree.get_root()
	if %PortraitTree.get_selected() and %PortraitTree.get_selected().get_metadata(0).has('group'):
		parent = %PortraitTree.get_selected()
	
	var dir := DirAccess.open(path)
	dir.list_dir_begin()
	var file_name :String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var file_lower = file_name.to_lower()
			if '.svg' in file_lower or '.png' in file_lower:
				if not '.import' in file_lower:
					var final_name: String= path+ "/" + file_name
					%PortraitTree.add_portrait_item(file_name.trim_suffix('.'+file_name.get_extension()), 
							{'scene':"",'image':final_name, 'scale':1, 'offset':Vector2(), 'mirror':false}, parent) 
		file_name = dir.get_next()
	something_changed()


func add_portrait(portrait_name:String='New portrait', portrait_data:Dictionary={'scene':"", 'image':'', 'scale':1, 'offset':Vector2(), 'mirror':false}) -> void:
	var parent: TreeItem = %PortraitTree.get_root()
	if %PortraitTree.get_selected():
		if %PortraitTree.get_selected().get_metadata(0).has('group'):
			parent = %PortraitTree.get_selected()
		else:
			parent = %PortraitTree.get_selected().get_parent()
	%PortraitTree.add_portrait_item(portrait_name, portrait_data, parent).select(0)
	something_changed()


func add_portrait_group() -> void:
	var parent_item :TreeItem = %PortraitTree.get_root()
	if %PortraitTree.get_selected() and %PortraitTree.get_selected().get_metadata(0).has('group'):
		parent_item = %PortraitTree.get_selected()
	%PortraitTree.add_portrait_group("Group", parent_item)


func load_portrait_tree() -> void:
	%PortraitTree.clear_tree()
	var root:TreeItem = %PortraitTree.create_item()
	
	for portrait in current_resource.portraits.keys():
		var portrait_label = portrait
		var parent = %PortraitTree.get_root()
		if '/' in portrait:
			parent = %PortraitTree.create_necessary_group_items(portrait)
			portrait_label = portrait.split('/')[-1]
		
		%PortraitTree.add_portrait_item(portrait_label, current_resource.portraits[portrait], parent)
	
	update_default_portrait_star(current_resource.default_portrait)
	
	if root.get_child_count():
		root.get_first_child().select(0)
	else:
		# Call anyways to clear preview and hide portrait settings section
		load_selected_portrait()


func filter_portrait_list(filter_term:String = '') -> void:
	filter_branch(%PortraitTree.get_root(), filter_term)


func filter_branch(parent:TreeItem, filter_term:String) -> bool:
	var anything_visible := false
	for item in parent.get_children():
		if item.get_metadata(0).has('group'):
			item.visible = filter_branch(item, filter_term)
			anything_visible = item.visible
		elif filter_term.is_empty() or filter_term.to_lower() in item.get_text(0).to_lower():
			item.visible = true
			anything_visible = true
		else:
			item.visible = false
	return anything_visible


# this is used to save the portrait data
func get_updated_portrait_dict() -> Dictionary:
	return list_portraits(%PortraitTree.get_root().get_children())


func list_portraits(tree_items:Array[TreeItem], dict:Dictionary = {}, path_prefix = "") -> Dictionary:
	for item in tree_items:
		if item.get_metadata(0).has('group'):
			dict = list_portraits(item.get_children(), dict, path_prefix+item.get_text(0)+"/")
		else:
			dict[path_prefix +item.get_text(0)] = item.get_metadata(0)
	return dict


func load_selected_portrait():
	if selected_item and is_instance_valid(selected_item):
		selected_item.set_editable(0, false)
	
	selected_item = %PortraitTree.get_selected()
	
	
	if selected_item and !selected_item.get_metadata(0).has('group'):
		%PortraitSettingsSection.show()
		var current_portrait_data :Dictionary = selected_item.get_metadata(0)
		portrait_selected.emit(%PortraitTree.get_full_item_name(selected_item), current_portrait_data)
		
		update_preview()
		
		for tab in %PortraitSettingsSection.get_children():
			if !tab is DialogicCharacterEditorPortraitSettingsTab:
				printerr("[Dialogic Editor] Portrait settings tabs should extend the right class!")
			else:
				tab.selected_item = selected_item
				tab._load_portrait_data(current_portrait_data)
		
		# switch tabs if the current one is hidden (until the next not hidden tab)
		for i in range(%PortraitSettingsSection.get_tab_count()):
			if %PortraitSettingsSection.is_tab_hidden(%PortraitSettingsSection.current_tab):
				if %PortraitSettingsSection.current_tab == %PortraitSettingsSection.get_tab_count()-1:
					%PortraitSettingsSection.current_tab = 0
				else:
					%PortraitSettingsSection.current_tab += 1
			else:
				break
	else:
		%PortraitSettingsSection.hide()
		update_preview()
	
	if selected_item:
		await get_tree().create_timer(0.01).timeout
		selected_item.set_editable(0, true)


func delete_portrait_item(item:TreeItem) -> void:
	item.free()
	something_changed()


func duplicate_item(item:TreeItem) -> void:
	%PortraitTree.add_portrait_item(item.get_text(0)+'_duplicated', item.get_metadata(0), item.get_parent()).select(0)


func _on_portrait_tree_button_clicked(item:TreeItem, column:int, id:int, mouse_button_index:int):
	# DELETE BUTTON
	if id == 1:
		delete_portrait_item(item)
	# DUPLICATE ITEM
	if id == 3:
		duplicate_item(item)


# this removes/and adds the DEFAULT star on the portrait list
func update_default_portrait_star(default_portrait_name:String) -> void:
	var item_list : Array = %PortraitTree.get_root().get_children()
	if item_list.is_empty() == false:
		while true:
			var item = item_list.pop_back()
			if item.get_button_by_id(0, 2) != -1:
				item.erase_button(0, item.get_button_by_id(0, 2))
			if %PortraitTree.get_full_item_name(item) == default_portrait_name:
				item.erase_button(0, item.get_button_by_id(0, 1))
				item.erase_button(0, item.get_button_by_id(0, 3))
				item.add_button(0, get_theme_icon('Favorites', 'EditorIcons'), 2, true, 'Default')
				item.add_button(0, get_theme_icon('Duplicate', 'EditorIcons'), 3, false, 'Duplicate')
				item.add_button(0, get_theme_icon('Remove', 'EditorIcons'), 1, false, 'Remove')
			item_list.append_array(item.get_children())
			
			if item_list.is_empty():
				break


func _on_item_edited():
	selected_item = %PortraitTree.get_selected()
	something_changed()
	if selected_item:
		if %PreviewLabel.text.trim_prefix('Preview of "').trim_suffix('"') == current_resource.default_portrait:
			current_resource.default_portrait = %PortraitTree.get_full_item_name(selected_item)
	update_preview()



##############################################################################
##						PORTRAIT SETTINGS TAB
##############################################################################

func setup_portrait_settings_tab() -> void:
	%DefaultPortraitPicker.value_changed.connect(default_portrait_changed)
	%MainScale.value_changed.connect(main_portrait_settings_update)
	%MainOffsetX.value_changed.connect(main_portrait_settings_update)
	%MainOffsetY.value_changed.connect(main_portrait_settings_update)
	%MainMirror.toggled.connect(main_portrait_settings_update)
	
	# Setting up Default Portrait Picker
	%DefaultPortraitPicker.resource_icon = load("res://addons/dialogic/Editor/Images/Resources/portrait.svg")
	%DefaultPortraitPicker.get_suggestions_func = suggest_portraits


# Make sure preview get's updated when portrait settings change
func main_portrait_settings_update(value = null) -> void:
	current_resource.scale = %MainScale.value/100.0
	current_resource.offset = Vector2(%MainOffsetX.value, %MainOffsetY.value) 
	current_resource.mirror = %MainMirror.button_pressed
	update_preview()
	something_changed()


func default_portrait_changed(property:String, value:String) -> void:
	current_resource.default_portrait = value
	update_default_portrait_star(value)


# Get suggestions for DefaultPortraitPicker
func suggest_portraits(search:String) -> Dictionary:
	var suggestions := {}
	for portrait in get_updated_portrait_dict().keys():
		suggestions[portrait] = {'value':portrait}
	return suggestions


##############################################################################
##							PREVIEW
##############################################################################

func update_preview() -> void:
	%ScenePreviewWarning.hide()
	if selected_item and is_instance_valid(selected_item) and !selected_item.get_metadata(0).has('group'):
		%PreviewLabel.text = 'Preview of "'+%PortraitTree.get_full_item_name(selected_item)+'"'
		var current_portrait_data: Dictionary = selected_item.get_metadata(0)
		var mirror:bool = current_portrait_data.get('mirror', false) != current_resource.mirror
		var scale:float = current_portrait_data.get('scale', 1) * current_resource.scale
		var offset:Vector2 =current_portrait_data.get('offset', Vector2()) + current_resource.offset
		
		if current_previewed_scene != null \
			and current_previewed_scene.get_meta('path', null) == current_portrait_data.get('scene') \
			and current_previewed_scene.has_method('_should_do_portrait_update') \
			and is_instance_valid(current_previewed_scene.get_script()) \
			and current_previewed_scene._should_do_portrait_update(current_resource, selected_item.get_text(0)):
			pass # we keep the same scene
		else:
			for node in %RealPreviewPivot.get_children():
				node.queue_free()
			current_previewed_scene = null
			if current_portrait_data.get('scene', '').is_empty():
				if FileAccess.file_exists("res://addons/dialogic/Events/Character/default_portrait.tscn"):
					current_previewed_scene = load("res://addons/dialogic/Events/Character/default_portrait.tscn").instantiate()
					current_previewed_scene.set_meta('path', '')
			else:
				if FileAccess.file_exists(current_portrait_data.get('scene')):
					current_previewed_scene = load(current_portrait_data.get('scene')).instantiate()
					current_previewed_scene.set_meta('path', current_portrait_data.get('scene'))
			if current_previewed_scene:
				%RealPreviewPivot.add_child(current_previewed_scene)

		if current_previewed_scene != null:
			var scene = current_previewed_scene
			scene.show_behind_parent = true
			
			for prop in current_portrait_data.get('export_overrides', {}).keys():
				scene.set(prop, str_to_var(current_portrait_data['export_overrides'][prop]))
			
			if is_instance_valid(scene.get_script()) and scene.script.is_tool():
				if scene.has_method('_update_portrait'):
					scene._update_portrait(current_resource, %PortraitTree.get_full_item_name(selected_item))
				if scene.has_method('_set_mirror'):
					scene._set_mirror(mirror)
			if current_preview_mode == PreviewModes.Real:
				scene.position = Vector2() + offset
				
				if current_portrait_data.get('scene', '').is_empty() or !current_portrait_data.get('ignore_char_scale', false):
					scene.scale = Vector2(1,1)*scale
			else:
				if  is_instance_valid(scene.get_script()) and scene.script.is_tool() and scene.has_method('_get_covered_rect'):
					var rect :Rect2= scene._get_covered_rect()
					var available_rect:Rect2 = %FullPreviewAvailableRect.get_rect()
					scene.scale = Vector2(1,1) * min(available_rect.size.x/rect.size.x, available_rect.size.y/rect.size.y)
					%RealPreviewPivot.position = (rect.position)*-1*scene.scale
					%RealPreviewPivot.position.x = %FullPreviewAvailableRect.size.x/2
					scene.position = Vector2()
				else:
					%ScenePreviewWarning.show()
		else:
			%PreviewRealRect.texture = null
			%PreviewFullRect.texture = null
			%PreviewLabel.text = 'Nothing to preview'
	
	else:
		%PreviewLabel.text = 'No portrait to preview.'
		for node in %RealPreviewPivot.get_children():
			node.queue_free()
		current_previewed_scene = null


func _on_PreviewMode_item_selected(index:int) -> void:
	current_preview_mode = index
	# FULL VIEW
	if index == PreviewModes.Full:
		%RealSizeRemotePivotTransform.update_position = false
	# REAL SIZE
	if index == PreviewModes.Real or index == null:
		%RealSizeRemotePivotTransform.update_position = true
	update_preview()
	ProjectSettings.set_setting('dialogic/editor/character_preview_mode', index)
	ProjectSettings.save()


func _on_full_preview_available_rect_resized():
	if current_preview_mode == PreviewModes.Full:
		update_preview()

