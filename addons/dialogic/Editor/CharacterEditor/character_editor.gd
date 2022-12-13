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
	current_resource = resource
	
	# make sure changes in the ui won't trigger saving
	loading = true
	
	## Load other main tabs
	for main_edit in %MainEditTabs.get_children():
		main_edit._load_character(current_resource)
	
	# Portrait section
	%PortraitSearch.text = ""
	load_portrait_tree()
	
	loading = false
	character_loaded.emit(resource.resource_path)


func _save_resource() -> void:
	if ! visible or not current_resource:
		return
	
	current_resource.portraits = get_updated_portrait_dict()
	
	for main_edit in %MainEditTabs.get_children():
		current_resource = main_edit._save_changes(current_resource)
	
	ResourceSaver.save(current_resource, current_resource.resource_path)
	current_resource_state = ResourceStates.Saved
	editors_manager.resource_helper.rebuild_character_directory()


# Saves a new empty character to the given path
func new_character(path: String) -> void:
	var resource = DialogicCharacter.new()
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
	## Portrait section styling/connections
	%AddPortraitButton.icon = get_theme_icon("Add", "EditorIcons")
	%AddPortraitButton.pressed.connect(add_portrait)
	%ImportPortraitsButton.icon = get_theme_icon("Folder", "EditorIcons")
	%ImportPortraitsButton.pressed.connect(open_portrait_folder_select)
	%PortraitSearch.right_icon = get_theme_icon("Search", "EditorIcons")
	%PortraitSearch.text_changed.connect(filter_portrait_list)
	
	%PortraitTree.item_selected.connect(load_selected_portrait)
	%PortraitTree.item_edited.connect(_on_item_edited)
	
	%PreviewMode.item_selected.connect(_on_PreviewMode_item_selected)
	%PreviewMode.select(DialogicUtil.get_project_setting('dialogic/editor/character_preview_mode', 0))
	_on_PreviewMode_item_selected(%PreviewMode.selected)
	
	## General Styling
	var panel_style = DCSS.inline({
		'border-radius': 5,
		'border': 1,
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
#		_save_resource() TODO, should this happen?


##############################################################################
##							PORTRAIT SECTION
##############################################################################

func open_portrait_folder_select() -> void:
	find_parent("EditorView").godot_file_dialog(
		import_portraits_from_folder, "*", 
		EditorFileDialog.FILE_MODE_OPEN_DIR)


func import_portraits_from_folder(path:String) -> void:
	var dir := DirAccess.open(path)
	dir.list_dir_begin()
	var file_name :String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var file_lower = file_name.to_lower()
			if '.svg' in file_lower or '.png' in file_lower:
				if not '.import' in file_lower:
					var final_name: String= path+ "/" + file_name
					add_portrait(file_name.trim_suffix('.'+file_name.get_extension()), 
							{'scene':"",'image':final_name, 'scale':1, 'offset':Vector2(), 'mirror':false}) 
		file_name = dir.get_next()


func add_portrait(portrait_name:String='New portrait', portrait_data:Dictionary={'scene':"", 'image':'', 'scale':1, 'offset':Vector2(), 'mirror':false}) -> void:
	var root: TreeItem = %PortraitTree.get_root()
	add_portrait_item(portrait_name, portrait_data, root).select(0)
	something_changed()


func load_portrait_tree() -> void:
	%PortraitTree.clear()
	var root:TreeItem = %PortraitTree.create_item()
	
	for portrait in current_resource.portraits.keys():
		add_portrait_item(portrait, current_resource.portraits[portrait], root)
	
	if root.get_child_count():
		root.get_first_child().select(0)



func filter_portrait_list(filter_term:String = '') -> void:
	var item : TreeItem = %PortraitTree.get_root().get_first_child()
	while true:
		item.visible = filter_term.is_empty() or filter_term.to_lower() in item.get_text(0).to_lower()
		item = item.get_next()
		if !item:
			break


# this is used to save the portrait data
func get_updated_portrait_dict() -> Dictionary:
	var dict : Dictionary = {}
	var item : TreeItem = %PortraitTree.get_root().get_first_child()
	while item:
		dict[item.get_text(0)] = item.get_metadata(0)
		item = item.get_next()
	return dict


func add_portrait_item(portrait_name:String, portrait_data:Dictionary, parent_item:TreeItem) -> TreeItem:
	var item :TreeItem = %PortraitTree.create_item(parent_item)
	item.set_text(0, portrait_name)
	item.set_metadata(0, portrait_data)
	if portrait_name == current_resource.default_portrait:
		item.add_button(0, get_theme_icon('Favorites', 'EditorIcons'), 2, true, 'Default')
	item.add_button(0, get_theme_icon('Duplicate', 'EditorIcons'), 3, false, 'Duplicate')
	item.add_button(0, get_theme_icon('Remove', 'EditorIcons'), 1, false, 'Remove')
	return item


func load_selected_portrait():
	if selected_item and is_instance_valid(selected_item):
		selected_item.set_editable(0, false)
	
	selected_item = %PortraitTree.get_selected()
	
	if selected_item:
		
		var current_portrait_data :Dictionary = selected_item.get_metadata(0)
		portrait_selected.emit(selected_item.get_text(0), current_portrait_data)
		
		update_preview()
		
		for tab in %PortraitSettingsSection.get_children():
			if !tab is DialogicCharacterEditorPortraitSettingsTab:
				printerr("[Dialogic Editor] Portrait settings tabs should extend the right class!")
			else:
				tab.selected_item = selected_item
				tab._load_portrait_data(current_portrait_data)
		
		await get_tree().create_timer(0.01).timeout
		selected_item.set_editable(0, true)


func delete_portrait_item(item:TreeItem) -> void:
	item.free()
	something_changed()


func duplicate_item(item:TreeItem) -> void:
	add_portrait_item(item.get_text(0)+'_duplicated', item.get_metadata(0), item.get_parent()).select(0)


func _on_portrait_tree_button_clicked(item:TreeItem, column:int, id:int, mouse_button_index:int):
	# DELETE BUTTON
	if id == 1:
		delete_portrait_item(item)
	# DUPLICATE ITEM
	if id == 3:
		duplicate_item(item)


func update_preview() -> void:
	for node in %RealPreviewPivot.get_children():
		node.queue_free()
	%ScenePreviewWarning.hide()
	if selected_item and is_instance_valid(selected_item):
		%PreviewLabel.text = 'Preview of "'+selected_item.get_text(0)+'"'
		var current_portrait_data: Dictionary = selected_item.get_metadata(0)
		var mirror:bool = current_portrait_data.get('mirror', false) != current_resource.mirror
		var scale:float = current_portrait_data.get('scale', 1) * current_resource.scale
		var offset:Vector2 =current_portrait_data.get('offset', Vector2()) + current_resource.offset
		
		var scene = null
		if current_portrait_data.get('scene', '').is_empty():
			scene = load("res://addons/dialogic/Events/Character/default_portrait.tscn")
		else:
			scene = load(current_portrait_data.get('scene'))
		
		if scene:
			scene = scene.instantiate()
			scene.show_behind_parent = true
			
			%RealPreviewPivot.add_child(scene)
			
			if is_instance_valid(scene.get_script()) and scene.script.is_tool():
				if scene.has_method('_update_portrait'):
					scene._update_portrait(current_resource, selected_item.get_text(0))
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


# this removes/and adds the DEFAULT star on the portrait list
func update_default_portrait_star(default_portrait_name:String) -> void:
	var item : TreeItem = %PortraitTree.get_root().get_first_child()
	while true:
		if item.get_button_by_id(0, 2) != -1:
			item.erase_button(0, item.get_button_by_id(0, 2))
		if item.get_text(0) == default_portrait_name:
			item.erase_button(0, item.get_button_by_id(0, 1))
			item.erase_button(0, item.get_button_by_id(0, 3))
			item.add_button(0, get_theme_icon('Favorites', 'EditorIcons'), 2, true, 'Default')
			item.add_button(0, get_theme_icon('Duplicate', 'EditorIcons'), 3, false, 'Duplicate')
			item.add_button(0, get_theme_icon('Remove', 'EditorIcons'), 1, false, 'Remove')
		item = item.get_next()
		if !item:
			break


func _on_item_edited():
	selected_item = %PortraitTree.get_selected()
	something_changed()
	if selected_item:
		if %PreviewLabel.text.trim_prefix('Preview of "').trim_suffix('"') == current_resource.default_portrait:
			current_resource.default_portrait = selected_item.get_text(0)
	update_preview()


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


func main_portrait_settings_update(value = null) -> void:
	update_preview()
	something_changed()


func _on_full_preview_available_rect_resized():
	if current_preview_mode == PreviewModes.Full:
		update_preview()
