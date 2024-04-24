@tool
extends DialogicEditor

## Editor for editing character resources.

signal character_loaded(resource_path:String)
signal portrait_selected()


# Current state
var loading := false
var current_previewed_scene = null

# References
var selected_item: TreeItem
var def_portrait_path :String= DialogicUtil.get_module_path('Character').path_join('default_portrait.tscn')


######### EDITOR STUFF and LOADING/SAVING ######################################

#region Resource Logic
## Method is called once editors manager is ready to accept registers.
func _register() -> void:
	## Makes the editor open this when a .dch file is selected.
	## Then _open_resource() is called.
	editors_manager.register_resource_editor("dch", self)

	## Add an "add character" button
	var add_character_button = editors_manager.add_icon_button(
			load("res://addons/dialogic/Editor/Images/Toolbar/add-character.svg"),
			'Add Character',
			self)
	add_character_button.pressed.connect(_on_create_character_button_pressed)
	add_character_button.shortcut = Shortcut.new()
	add_character_button.shortcut.events.append(InputEventKey.new())
	add_character_button.shortcut.events[0].keycode = KEY_2
	add_character_button.shortcut.events[0].ctrl_pressed = true

	## By default show the no character screen
	$NoCharacterScreen.show()


func _get_title() -> String:
	return "Character"


func _get_icon() -> Texture:
	return load("res://addons/dialogic/Editor/Images/Resources/character.svg")


## Called when a character is opened somehow
func _open_resource(resource:Resource) -> void:
	if resource == null:
		$NoCharacterScreen.show()
		return

	## Update resource
	current_resource = (resource as DialogicCharacter)

	## Make sure changes in the ui won't trigger saving
	loading = true

	## Load other main tabs
	for child in %MainSettingsSections.get_children():
		if child is DialogicCharacterEditorMainSection:
			child._load_character(current_resource)

	## Clear and then load Portrait section
	%PortraitSearch.text = ""
	load_portrait_tree()

	loading = false
	character_loaded.emit(resource.resource_path)

	%CharacterName.text = DialogicResourceUtil.get_unique_identifier(resource.resource_path)

	$NoCharacterScreen.hide()
	%PortraitChangeInfo.hide()


## Called when the character is opened.
func _open(extra_info:Variant="") -> void:
	if !ProjectSettings.get_setting('dialogic/portraits/default_portrait', '').is_empty():
		def_portrait_path = ProjectSettings.get_setting('dialogic/portraits/default_portrait', '')
	else:
		def_portrait_path = DialogicUtil.get_module_path('Character').path_join('default_portrait.tscn')

	if current_resource == null:
		$NoCharacterScreen.show()
		return

	update_preview(true)
	%PortraitChangeInfo.hide()


func _clear() -> void:
	current_resource = null
	current_resource_state = ResourceStates.SAVED
	$NoCharacterScreen.show()


func _save() -> void:
	if ! visible or not current_resource:
		return

	## Portrait list
	current_resource.portraits = get_updated_portrait_dict()

	## Main tabs
	for child in %MainSettingsSections.get_children():
		if child is DialogicCharacterEditorMainSection:
			current_resource = child._save_changes(current_resource)

	ResourceSaver.save(current_resource, current_resource.resource_path)
	current_resource_state = ResourceStates.SAVED
	DialogicResourceUtil.update_directory('dch')


## Saves a new empty character to the given path
func new_character(path: String) -> void:
	var resource := DialogicCharacter.new()
	resource.resource_path = path
	resource.display_name = path.get_file().trim_suffix("."+path.get_extension())
	resource.color = Color(1,1,1,1)
	resource.default_portrait = ""
	resource.custom_info = {}
	ResourceSaver.save(resource, path)
	DialogicResourceUtil.update_directory('dch')
	editors_manager.edit_resource(resource)

#endregion


######### INTERFACE ############################################################

#region Interface
func _ready() -> void:
	if get_parent() is SubViewport:
		return

	DialogicUtil.get_dialogic_plugin().resource_saved.connect(_on_some_resource_saved)
	# NOTE: This check is required because up to 4.2 this signal is not exposed.
	if DialogicUtil.get_dialogic_plugin().has_signal("scene_saved"):
		DialogicUtil.get_dialogic_plugin().scene_saved.connect(_on_some_resource_saved)

	$NoCharacterScreen.color = get_theme_color("dark_color_2", "Editor")
	$NoCharacterScreen.show()
	setup_portrait_list_tab()

	_on_fit_preview_toggle_toggled(DialogicUtil.get_editor_setting('character_preview_fit', true))
	%PreviewLabel.add_theme_color_override("font_color", get_theme_color("readonly_color", "Editor"))

	%PortraitChangeWarning.add_theme_color_override("font_color", get_theme_color("warning_color", "Editor"))

	%RealPreviewPivot.texture = get_theme_icon("EditorPivot", "EditorIcons")

	%MainSettingsCollapse.icon = get_theme_icon("GuiVisibilityVisible", "EditorIcons")

	set_portrait_settings_position(DialogicUtil.get_editor_setting('portrait_settings_position', true))

	await find_parent('EditorView').ready

	## Add general tabs
	add_settings_section(load("res://addons/dialogic/Editor/CharacterEditor/char_edit_section_general.tscn").instantiate(), %MainSettingsSections)
	add_settings_section(load("res://addons/dialogic/Editor/CharacterEditor/char_edit_section_portraits.tscn").instantiate(), %MainSettingsSections)


	add_settings_section(load("res://addons/dialogic/Editor/CharacterEditor/char_edit_p_section_main_exports.tscn").instantiate(), %PortraitSettingsSection)
	add_settings_section(load("res://addons/dialogic/Editor/CharacterEditor/char_edit_p_section_exports.tscn").instantiate(), %PortraitSettingsSection)
	add_settings_section(load("res://addons/dialogic/Editor/CharacterEditor/char_edit_p_section_main.tscn").instantiate(), %PortraitSettingsSection)
	add_settings_section(load("res://addons/dialogic/Editor/CharacterEditor/char_edit_p_section_layout.tscn").instantiate(), %PortraitSettingsSection)

	## Load custom sections from modules
	for indexer in DialogicUtil.get_indexers():
		for path in indexer._get_character_editor_sections():
			var scene: Control = load(path).instantiate()
			if scene is DialogicCharacterEditorMainSection:
				add_settings_section(scene, %MainSettingsSections)
			elif scene is DialogicCharacterEditorPortraitSection:
				add_settings_section(scene, %PortraitSettingsSection)


## Add a section (a control) either to the given settings section (Main or Portraits)
## - sets up the title of the section
## - connects to various signals
func add_settings_section(edit:Control, parent:Node) ->  void:
	edit.changed.connect(something_changed)
	edit.character_editor = self
	if edit.has_signal('update_preview'):
		edit.update_preview.connect(update_preview)

	var button :Button
	if edit._show_title():
		var hbox := HBoxContainer.new()
		hbox.name = edit._get_title()+"BOX"
		button = Button.new()
		button.flat = true
		button.theme_type_variation = "DialogicSection"
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.text = edit._get_title()
		button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		button.pressed.connect(_on_section_button_pressed.bind(button))
		button.focus_mode = Control.FOCUS_NONE
		button.icon = get_theme_icon("CodeFoldDownArrow", "EditorIcons")
		button.add_theme_color_override('icon_normal_color', get_theme_color("font_color", "DialogicSection"))

		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(button)

		if !edit.hint_text.is_empty():
			var hint :Node = load("res://addons/dialogic/Editor/Common/hint_tooltip_icon.tscn").instantiate()
			hint.hint_text = edit.hint_text
			hbox.add_child(hint)

		parent.add_child(hbox)
	parent.add_child(edit)
	parent.add_child(HSeparator.new())
	if button and !edit._start_opened():
		_on_section_button_pressed(button)


func get_settings_section_by_name(name:String, main:=true) -> Node:
	var parent := %MainSettingsSections
	if not main:
		parent = %PortraitSettingsSection

	if parent.has_node(name):
		return parent.get_node(name)
	elif parent.has_node(name+"BOX/"+name):
		return parent.get_node(name+"BOX/"+name)
	else:
		return null


func _on_section_button_pressed(button:Button) -> void:
	var section_header := button.get_parent()
	var section := section_header.get_parent().get_child(section_header.get_index()+1)
	if section.visible:
		button.icon = get_theme_icon("CodeFoldedRightArrow", "EditorIcons")
		section.visible = false
	else:
		button.icon = get_theme_icon("CodeFoldDownArrow", "EditorIcons")
		section.visible = true

	if section_header.get_parent().get_child_count() > section_header.get_index()+2 and section_header.get_parent().get_child(section_header.get_index()+2) is Separator:
		section_header.get_parent().get_child(section_header.get_index()+2).visible = section_header.get_parent().get_child(section_header.get_index()+1).visible


func something_changed(fake_argument = "", fake_arg2 = null) -> void:
	if not loading:
		current_resource_state = ResourceStates.UNSAVED


func _on_main_settings_collapse_toggled(button_pressed:bool) -> void:
	%MainSettingsTitle.visible = !button_pressed
	%MainSettingsScroll.visible = !button_pressed
	if button_pressed:
		%MainSettings.hide()
		%MainSettingsCollapse.icon = get_theme_icon("GuiVisibilityHidden", "EditorIcons")
	else:
		%MainSettings.show()
		%MainSettingsCollapse.icon = get_theme_icon("GuiVisibilityVisible", "EditorIcons")


func _on_switch_portrait_settings_position_pressed() -> void:
	set_portrait_settings_position(!%RightSection.vertical)


func set_portrait_settings_position(is_below:bool) -> void:
	%RightSection.vertical = is_below
	DialogicUtil.set_editor_setting('portrait_settings_position', is_below)
	if is_below:
		%SwitchPortraitSettingsPosition.icon = get_theme_icon("ControlAlignRightWide", "EditorIcons")
	else:
		%SwitchPortraitSettingsPosition.icon = get_theme_icon("ControlAlignBottomWide", "EditorIcons")

#endregion


########## PORTRAIT SECTION ####################################################

#region Portrait Section
func setup_portrait_list_tab() -> void:
	%PortraitTree.editor = self

	## Portrait section styling/connections
	%AddPortraitButton.icon = get_theme_icon("Add", "EditorIcons")
	%AddPortraitButton.pressed.connect(add_portrait)
	%AddPortraitGroupButton.icon = load("res://addons/dialogic/Editor/Images/Pieces/add-folder.svg")
	%AddPortraitGroupButton.pressed.connect(add_portrait_group)
	%ImportPortraitsButton.icon = get_theme_icon("Load", "EditorIcons")
	%ImportPortraitsButton.pressed.connect(open_portrait_folder_select)
	%PortraitSearch.right_icon = get_theme_icon("Search", "EditorIcons")
	%PortraitSearch.text_changed.connect(filter_portrait_list)

	%PortraitTree.item_selected.connect(load_selected_portrait)
	%PortraitTree.item_edited.connect(_on_item_edited)
	%PortraitTree.item_activated.connect(_on_item_activated)


func open_portrait_folder_select() -> void:
	find_parent("EditorView").godot_file_dialog(
		import_portraits_from_folder, "*.svg, *.png",
		EditorFileDialog.FILE_MODE_OPEN_DIR)


func import_portraits_from_folder(path:String) -> void:
	var parent: TreeItem = %PortraitTree.get_root()

	if %PortraitTree.get_selected() and %PortraitTree.get_selected() != parent and %PortraitTree.get_selected().get_metadata(0).has('group'):
		parent = %PortraitTree.get_selected()

	var dir := DirAccess.open(path)
	dir.list_dir_begin()
	var file_name :String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var file_lower = file_name.to_lower()
			if '.svg' in file_lower or '.png' in file_lower:
				if not '.import' in file_lower:
					var final_name: String = path.path_join(file_name)
					%PortraitTree.add_portrait_item(file_name.trim_suffix('.'+file_name.get_extension()),
							{'scene':"",'export_overrides':{'image':var_to_str(final_name)}, 'scale':1, 'offset':Vector2(), 'mirror':false}, parent)
		file_name = dir.get_next()

	## Handle selection
	if parent.get_child_count():
		parent.get_first_child().select(0)
	else:
		# Call anyways to clear preview and hide portrait settings section
		load_selected_portrait()

	something_changed()


func add_portrait(portrait_name:String='New portrait', portrait_data:Dictionary={'scene':"", 'export_overrides':{'image':''}, 'scale':1, 'offset':Vector2(), 'mirror':false}) -> void:
	var parent: TreeItem = %PortraitTree.get_root()
	if %PortraitTree.get_selected():
		if %PortraitTree.get_selected().get_metadata(0) and %PortraitTree.get_selected().get_metadata(0).has('group'):
			parent = %PortraitTree.get_selected()
		else:
			parent = %PortraitTree.get_selected().get_parent()
	var item: TreeItem = %PortraitTree.add_portrait_item(portrait_name, portrait_data, parent)
	item.set_meta('new', true)
	item.set_editable(0, true)
	item.select(0)
	%PortraitTree.call_deferred('edit_selected')
	something_changed()


func add_portrait_group() -> void:
	var parent_item: TreeItem = %PortraitTree.get_root()
	if %PortraitTree.get_selected() and %PortraitTree.get_selected().get_metadata(0).has('group'):
		parent_item = %PortraitTree.get_selected()
	var item :TreeItem = %PortraitTree.add_portrait_group("Group", parent_item)
	item.set_meta('new', true)
	item.set_editable(0, true)
	item.select(0)
	%PortraitTree.call_deferred('edit_selected')


func load_portrait_tree() -> void:
	%PortraitTree.clear_tree()
	var root: TreeItem = %PortraitTree.create_item()

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
		while %PortraitTree.get_selected().get_child_count():
			%PortraitTree.get_selected().get_child(0).select(0)
	else:
		# Call anyways to clear preview and hide portrait settings section
		load_selected_portrait()


func filter_portrait_list(filter_term := "") -> void:
	filter_branch(%PortraitTree.get_root(), filter_term)


func filter_branch(parent: TreeItem, filter_term: String) -> bool:
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


## This is used to save the portrait data
func get_updated_portrait_dict() -> Dictionary:
	return list_portraits(%PortraitTree.get_root().get_children())


func list_portraits(tree_items: Array[TreeItem], dict := {}, path_prefix := "") -> Dictionary:
	for item in tree_items:
		if item.get_metadata(0).has('group'):
			dict = list_portraits(item.get_children(), dict, path_prefix+item.get_text(0)+"/")
		else:
			dict[path_prefix +item.get_text(0)] = item.get_metadata(0)
	return dict


func load_selected_portrait() -> void:
	if selected_item and is_instance_valid(selected_item):
		selected_item.set_editable(0, false)

	selected_item = %PortraitTree.get_selected()

	if selected_item and selected_item.get_metadata(0) != null and !selected_item.get_metadata(0).has('group'):
		%PortraitSettingsSection.show()
		var current_portrait_data: Dictionary = selected_item.get_metadata(0)
		portrait_selected.emit(%PortraitTree.get_full_item_name(selected_item), current_portrait_data)

		update_preview()

		for child in %PortraitSettingsSection.get_children():
			if child is DialogicCharacterEditorPortraitSection:
				child.selected_item = selected_item
				child._load_portrait_data(current_portrait_data)

	else:
		%PortraitSettingsSection.hide()
		update_preview()


func delete_portrait_item(item: TreeItem) -> void:
	if item.get_next_visible(true) and item.get_next_visible(true) != item:
		item.get_next_visible(true).select(0)
	else:
		selected_item = null
		load_selected_portrait()
	item.free()
	something_changed()


func duplicate_item(item: TreeItem) -> void:
	var new_item: TreeItem = %PortraitTree.add_portrait_item(item.get_text(0)+'_duplicated', item.get_metadata(0).duplicate(true), item.get_parent())
	new_item.set_meta('new', true)
	new_item.select(0)


func _input(event: InputEvent) -> void:
	if !is_visible_in_tree() or (get_viewport().gui_get_focus_owner()!= null and !name+'/' in str(get_viewport().gui_get_focus_owner().get_path())):
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F2 and %PortraitTree.get_selected():
			%PortraitTree.get_selected().set_editable(0, true)
			%PortraitTree.edit_selected()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DELETE and get_viewport().gui_get_focus_owner() is Tree and %PortraitTree.get_selected():
			delete_portrait_item(%PortraitTree.get_selected())
			get_viewport().set_input_as_handled()


func _on_portrait_right_click_menu_index_pressed(id: int) -> void:
	# RENAME BUTTON
	if id == 0:
		_on_item_activated()
	# DELETE BUTTON
	if id == 2:
		delete_portrait_item(%PortraitTree.get_selected())
	# DUPLICATE ITEM
	elif id == 1:
		duplicate_item(%PortraitTree.get_selected())
	elif id == 4:
		get_settings_section_by_name("Portraits").set_default_portrait(%PortraitTree.get_full_item_name(%PortraitTree.get_selected()))


## This removes/and adds the DEFAULT star on the portrait list
func update_default_portrait_star(default_portrait_name: String) -> void:
	var item_list: Array = %PortraitTree.get_root().get_children()
	if item_list.is_empty() == false:
		while true:
			var item := item_list.pop_back()
			if item.get_button_by_id(0, 2) != -1:
				item.erase_button(0, item.get_button_by_id(0, 2))
			if %PortraitTree.get_full_item_name(item) == default_portrait_name:
				item.add_button(0, get_theme_icon("Favorites", "EditorIcons"), 2, true, "Default")
			item_list.append_array(item.get_children())
			if item_list.is_empty():
				break


func _on_item_edited() -> void:
	selected_item = %PortraitTree.get_selected()
	something_changed()
	if selected_item:
		if %PreviewLabel.text.trim_prefix('Preview of "').trim_suffix('"') == current_resource.default_portrait:
			current_resource.default_portrait = %PortraitTree.get_full_item_name(selected_item)
		selected_item.set_editable(0, false)

		if !selected_item.has_meta('new') and %PortraitTree.get_full_item_name(selected_item) != selected_item.get_meta('previous_name'):
			report_name_change(selected_item)
			%PortraitChangeInfo.show()
	update_preview()


func _on_item_activated() -> void:
	if %PortraitTree.get_selected() == null:
		return
	%PortraitTree.get_selected().set_editable(0, true)
	%PortraitTree.edit_selected()


func report_name_change(item: TreeItem) -> void:
	if item.get_metadata(0).has('group'):
		for s_item in item.get_children():
			if s_item.get_metadata(0).has('group') or !s_item.has_meta('new'):
				report_name_change(s_item)
	else:
		if item.get_meta('previous_name') == %PortraitTree.get_full_item_name(item):
			return
		editors_manager.reference_manager.add_portrait_ref_change(
			item.get_meta('previous_name'),
			%PortraitTree.get_full_item_name(item),
			[DialogicResourceUtil.get_unique_identifier(current_resource.resource_path)])
	item.set_meta('previous_name', %PortraitTree.get_full_item_name(item))
	%PortraitChangeInfo.show()

#endregion

########### PREVIEW ############################################################

#region Preview
func update_preview(force := false) -> void:
	%ScenePreviewWarning.hide()
	if selected_item and is_instance_valid(selected_item) and selected_item.get_metadata(0) != null and !selected_item.get_metadata(0).has('group'):
		%PreviewLabel.text = 'Preview of "'+%PortraitTree.get_full_item_name(selected_item)+'"'

		var current_portrait_data: Dictionary = selected_item.get_metadata(0)

		if not force and current_previewed_scene != null \
			and current_previewed_scene.get_meta('path', '') == current_portrait_data.get('scene') \
			and current_previewed_scene.has_method('_should_do_portrait_update') \
			and is_instance_valid(current_previewed_scene.get_script()) \
			and current_previewed_scene._should_do_portrait_update(current_resource, selected_item.get_text(0)):
			pass # we keep the same scene
		else:
			for node in %RealPreviewPivot.get_children():
				node.queue_free()

			current_previewed_scene = null

			var scene_path := def_portrait_path
			if not current_portrait_data.get('scene', '').is_empty():
				scene_path = current_portrait_data.get('scene')

			if ResourceLoader.exists(scene_path):
				current_previewed_scene = load(scene_path).instantiate()

			if current_previewed_scene:
				%RealPreviewPivot.add_child(current_previewed_scene)

		if current_previewed_scene != null:
			var scene: Node = current_previewed_scene

			scene.show_behind_parent = true
			DialogicUtil.apply_scene_export_overrides(scene, current_portrait_data.get('export_overrides', {}))

			var mirror: bool = current_portrait_data.get('mirror', false) != current_resource.mirror
			var scale: float = current_portrait_data.get('scale', 1) * current_resource.scale
			if current_portrait_data.get('ignore_char_scale', false):
				scale = current_portrait_data.get('scale', 1)
			var offset: Vector2 = current_portrait_data.get('offset', Vector2()) + current_resource.offset

			if is_instance_valid(scene.get_script()) and scene.script.is_tool():
				if scene.has_method('_update_portrait'):
					## Create a fake duplicate resource that has all the portrait changes applied already
					var preview_character := current_resource.duplicate()
					preview_character.portraits = get_updated_portrait_dict()
					scene._update_portrait(preview_character, %PortraitTree.get_full_item_name(selected_item))
				if scene.has_method('_set_mirror'):
					scene._set_mirror(mirror)

			if !%FitPreview_Toggle.button_pressed:
				scene.position = Vector2() + offset
				scene.scale = Vector2(1,1)*scale
			else:
				if is_instance_valid(scene.get_script()) and scene.script.is_tool() and scene.has_method('_get_covered_rect'):
					var rect: Rect2= scene._get_covered_rect()
					var available_rect: Rect2 = %FullPreviewAvailableRect.get_rect()
					scene.scale = Vector2(1,1) * min(available_rect.size.x/rect.size.x, available_rect.size.y/rect.size.y)
					%RealPreviewPivot.position = (rect.position)*-1*scene.scale
					%RealPreviewPivot.position.x = %FullPreviewAvailableRect.size.x/2
					scene.position = Vector2()
				else:
					%ScenePreviewWarning.show()
		else:
			%PreviewLabel.text = 'Nothing to preview'
		for child in %PortraitSettingsSection.get_children():
			if child is DialogicCharacterEditorPortraitSection:
				child._recheck(current_portrait_data)
	else:
		%PreviewLabel.text = 'No portrait to preview.'
		for node in %RealPreviewPivot.get_children():
			node.queue_free()
		current_previewed_scene = null


func _on_some_resource_saved(file:Variant) -> void:
	if current_previewed_scene == null:
		return

	if file is Resource and file == current_previewed_scene.script:
		update_preview(true)

	if typeof(file) == TYPE_STRING and file == current_previewed_scene.get_meta("path", ""):
		update_preview(true)


func _on_full_preview_available_rect_resized():
	if %FitPreview_Toggle.button_pressed:
		update_preview()


func _on_create_character_button_pressed():
	editors_manager.show_add_resource_dialog(
			new_character,
			'*.dch; DialogicCharacter',
			'Create new character',
			'character',
			)


func _on_fit_preview_toggle_toggled(button_pressed):
	%FitPreview_Toggle.set_pressed_no_signal(button_pressed)
	if button_pressed:
		%FitPreview_Toggle.icon = get_theme_icon("ScrollContainer", "EditorIcons")
		%FitPreview_Toggle.tooltip_text = "Real scale"
	else:
		%FitPreview_Toggle.tooltip_text = "Fit into preview"
		%FitPreview_Toggle.icon = get_theme_icon("CenterContainer", "EditorIcons")
	DialogicUtil.set_editor_setting('character_preview_fit', button_pressed)
	update_preview()

#endregion

## Open the reference manager
func _on_reference_manger_button_pressed():
	editors_manager.reference_manager.open()
	%PortraitChangeInfo.hide()

