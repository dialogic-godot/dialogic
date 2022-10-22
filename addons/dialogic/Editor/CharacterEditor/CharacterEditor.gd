@tool
extends Control

enum PreviewModes {Full, Real}
var current_preview_mode = PreviewModes.Full

var loading = false

var current_character : DialogicCharacter
var selected_item:TreeItem 

signal set_resource_unsaved
signal set_resource_saved
signal character_loaded(resource_path:String)
signal portrait_selected()

##############################################################################
##							RESOURCE LOGIC
##############################################################################

func new_character(path: String) -> void:
	var resource = DialogicCharacter.new()
	resource.resource_path = path
	resource.display_name = path.get_file().trim_suffix("."+path.get_extension())
	resource.color = Color(1,1,1,1)
	resource.default_portrait = ""
	resource.custom_info = {}
	ResourceSaver.save(resource, path)
	find_parent('EditorView').edit_character(resource)

func load_character(resource: DialogicCharacter) -> void:
	if not resource:
		return
	loading = true
	current_character = resource
	%ColorPickerButton.color = resource.color
	%DisplayNameLineEdit.text = resource.display_name
	%NicknameLineEdit.text = ""
	for nickname in resource.nicknames: 
		%NicknameLineEdit.text += nickname +", "
	%NicknameLineEdit.text = %NicknameLineEdit.text.trim_suffix(', ')
	%DescriptionTextEdit.text = resource.description
	%DefaultPortraitPicker.set_value(resource.default_portrait)
	%MainScale.value = 100*resource.scale
	%MainOffsetX.value = resource.offset.x
	%MainOffsetY.value = resource.offset.y
	%MainMirror.button_pressed = resource.mirror
	%PortraitSearch.text = ""
	
	for main_edit in %MainEditTabs.get_children():
		if main_edit.has_method('load_character'):
			main_edit.load_character(current_character)
	
	load_portrait_tree()
	loading = false
	emit_signal('character_loaded', resource.resource_path)


func save_character() -> void:
	if ! visible or not current_character:
		return
	current_character.display_name = %DisplayNameLineEdit.text
	current_character.color = %ColorPickerButton.color
	var nicknames = []
	for n_name in %NicknameLineEdit.text.split(','):
		nicknames.append(n_name.strip_edges())
	current_character.nicknames = nicknames
	current_character.description = %DescriptionTextEdit.text
	
	current_character.portraits = get_updated_portrait_dict()

	if $'%DefaultPortraitPicker'.current_value in current_character.portraits.keys():
		current_character.default_portrait = $'%DefaultPortraitPicker'.current_value
	elif !current_character.portraits.is_empty():
		current_character.default_portrait = current_character.portraits.keys()[0]
	else:
		current_character.default_portrait = ""
	
	current_character.scale = %MainScale.value/100.0
	current_character.offset = Vector2(%MainOffsetX.value, %MainOffsetY.value) 
	current_character.mirror = %MainMirror.button_pressed
	
	for main_edit in %MainEditTabs.get_children():
		if main_edit.has_method('save_character'):
			main_edit.save_character(current_character)
	
	ResourceSaver.save(current_character, current_character.resource_path)
	emit_signal('set_resource_saved')
	find_parent('EditorView').rebuild_character_directory()


##############################################################################
##							INTERFACE
##############################################################################

func _ready() -> void:
	DialogicUtil.get_dialogic_plugin().dialogic_save.connect(save_character)
	# Let's go connecting!
	%ColorPickerButton.color_changed.connect(something_changed)
	%DisplayNameLineEdit.text_changed.connect(something_changed)
	%NicknameLineEdit.text_changed.connect(something_changed)
	%DescriptionTextEdit.text_changed.connect(something_changed)
	%DefaultPortraitPicker.resource_icon = load("res://addons/dialogic/Editor/Images/Resources/Portrait.svg")
	%DefaultPortraitPicker.get_suggestions_func = suggest_portraits
	%DefaultPortraitPicker.set_left_text("")
	%DefaultPortraitPicker.value_changed.connect(default_portrait_changed)
	%MainScale.value_changed.connect(main_portrait_settings_update)
	%MainOffsetX.value_changed.connect(main_portrait_settings_update)
	%MainOffsetY.value_changed.connect(main_portrait_settings_update)
	%MainMirror.toggled.connect(main_portrait_settings_update)
#
	%AddPortraitButton.pressed.connect(add_portrait)
	%ImportPortraitsButton.pressed.connect(open_portrait_folder_select)
	%PortraitSearch.text_changed.connect(filter_portrait_list)
	
	%PortraitTree.item_selected.connect(load_selected_portrait)
	%PortraitTree.item_edited.connect(_on_item_edited)
	
	%PreviewMode.item_selected.connect(_on_PreviewMode_item_selected)
	%PreviewMode.select(DialogicUtil.get_project_setting('dialogic/editor/character_preview_mode', 0))
	_on_PreviewMode_item_selected(%PreviewMode.selected)
	
	# Let's go styling!
	self_modulate = get_theme_color("dark_color_3", "Editor")
	
	%AddPortraitButton.icon = get_theme_icon("Add", "EditorIcons")
	%ImportPortraitsButton.icon = get_theme_icon("Folder", "EditorIcons")
	%PortraitSearch.right_icon = get_theme_icon("Search", "EditorIcons")
	
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

	# Subsystems
	for script in DialogicUtil.get_event_scripts():
		for subsystem in load(script).new().get_required_subsystems():
			if subsystem.has('character_main'):
				var edit =  load(subsystem.character_main).instantiate()
				if edit.has_signal('changed'):
					edit.changed.connect(something_changed)
				%MainEditTabs.add_child(edit)
	hide()

func something_changed(fake_argument = "", fake_arg2 = null) -> void:
	if ! loading:
		emit_signal('set_resource_unsaved')
		save_character()

func suggest_portraits(search:String):
	var suggestions = {}
	for portrait in get_updated_portrait_dict().keys():
		if search.is_empty() or search.to_lower() in portrait.to_lower():
			suggestions[portrait] = {'value':portrait}
	return suggestions

func open_portrait_folder_select() -> void:
	find_parent("EditorView").godot_file_dialog(import_portraits_from_folder, "*", EditorFileDialog.FILE_MODE_OPEN_DIR)


func import_portraits_from_folder(path:String) -> void:
	var dir := DirAccess.open(path)
	dir.list_dir_begin()
	var file_name :String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var file_lower = file_name.to_lower()
			if '.svg' in file_lower or '.png' in file_lower:
				if not '.import' in file_lower:
					var final_name :String= path+ "/" + file_name
					add_portrait(file_name.trim_suffix('.'+file_name.get_extension()), {'scene':"",'image':final_name, 'scale':1, 'offset':Vector2(), 'mirror':false}) 
		file_name = dir.get_next()


func add_portrait(portrait_name:String='New portrait', portrait_data:Dictionary={'scene':"", 'image':'', 'scale':1, 'offset':Vector2(), 'mirror':false}) -> void:
	var root = %PortraitTree.get_root()
	add_portrait_item(portrait_name, portrait_data, root).select(0)
	something_changed()


func load_portrait_tree() -> void:
	%PortraitTree.clear()
	var root = %PortraitTree.create_item()
	
	for portrait in current_character.portraits.keys():
		add_portrait_item(portrait, current_character.portraits[portrait], root)
	
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
	if portrait_name == current_character.default_portrait:
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
			if tab.has_method('load_portrait_data'):
				tab.load_portrait_data(selected_item, current_portrait_data)
		
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
		var current_portrait_data :Dictionary = selected_item.get_metadata(0)
		var mirror:bool = current_portrait_data.get('mirror', false) != %MainMirror.button_pressed
		var scale:float = current_portrait_data.get('scale', 1) * %MainScale.value/100.0
		var offset:Vector2 =current_portrait_data.get('offset', Vector2()) + Vector2(%MainOffsetX.value, %MainOffsetY.value)
		
		var scene = null
		if current_portrait_data.get('scene', '').is_empty():
			scene = load("res://addons/dialogic/Events/Character/DefaultPortrait.tscn")
		else:
			scene = load(current_portrait_data.get('scene'))
		
		if scene:
			scene = scene.instantiate()
			scene.show_behind_parent = true
			
			%RealPreviewPivot.add_child(scene)
			
			if scene.script.is_tool():
				if scene.has_method('_update_portrait'):
					scene._update_portrait(current_character, selected_item.get_text(0))
				if scene.has_method('_set_mirror'):
					scene._set_mirror(mirror)
			
			if current_preview_mode == PreviewModes.Real:
				scene.position = Vector2() + offset
				
				if current_portrait_data.get('scene', '').is_empty() or !current_portrait_data.get('ignore_char_scale', false):
					scene.scale = Vector2(1,1)*scale
			else:
				if scene.script.is_tool() and scene.has_method('_get_covered_rect'):
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
func default_portrait_changed(property:String, text:String) -> void:
	var item : TreeItem = %PortraitTree.get_root().get_first_child()
	while true:
		if item.get_button_by_id(0, 2) != -1:
			item.erase_button(0, item.get_button_by_id(0, 2))
		if item.get_text(0) == text:
			item.erase_button(0, item.get_button_by_id(0, 1))
			item.erase_button(0, item.get_button_by_id(0, 3))
			item.add_button(0, get_theme_icon('Favorites', 'EditorIcons'), 2, true, 'Default')
			item.add_button(0, get_theme_icon('Duplicate', 'EditorIcons'), 3, false, 'Duplicate')
			item.add_button(0, get_theme_icon('Remove', 'EditorIcons'), 1, false, 'Remove')
		item = item.get_next()
		if !item:
			break
	something_changed()
	

func _on_item_edited():
	selected_item = %PortraitTree.get_selected()
	something_changed()
	if selected_item:
		if %PreviewLabel.text.trim_prefix('Preview of "').trim_suffix('"') == %DefaultPortraitPicker.current_value:
			%DefaultPortraitPicker.set_value(selected_item.get_text(0))
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
