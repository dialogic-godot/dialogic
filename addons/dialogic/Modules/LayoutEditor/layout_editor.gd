@tool
extends DialogicEditor

#enum LayoutModes {PRESET, CUSTOM, NONE}

var style_list := {}
var default_style := ""

var preset_info := {}
var customization_editor_info := {}

# the current style-configuration
var current_style := ""
# the layout scene path of the current style-configuration
var current_layout := ""


################################################################################
##						EDITOR REGISTERING
################################################################################

func _get_title() -> String:
	return "Styles"


func _get_icon() -> Texture:
	return load(DialogicUtil.get_module_path('LayoutEditor').path_join("styles_icon.svg"))


## Overwrite. Register to the editor manager in here.
func _register() -> void:
	editors_manager.register_simple_editor(self)
	alternative_text = "Change the look of the dialog in your game"


func _open(argument:Variant = null) -> void:
	pass


##					STYLE LIST FUNCTIONALITY
################################################################################
func _ready() -> void:
	for indexer in DialogicUtil.get_indexers():
		for layout in indexer._get_layout_parts():
			preset_info[layout['path']] = layout

	style_list = ProjectSettings.get_setting('dialogic/layout/styles', {})
	if style_list.is_empty():
		style_list = {"Default":DialogicUtil.get_default_style_info()}

	default_style = ProjectSettings.get_setting('dialogic/layout/default_style', 'Default')
	%AddButton.icon = get_theme_icon("Add", "EditorIcons")
	%DuplicateButton.icon = get_theme_icon("Duplicate", "EditorIcons")
	%InheritanceButton.icon = get_theme_icon("GuiDropdown", "EditorIcons")
	%RemoveButton.icon = get_theme_icon("Remove", "EditorIcons")

	%StyleList.item_selected.connect(_on_style_clicked)
	%AddButton.get_popup().index_pressed.connect(_on_add_style_index_pressed)

	%EditNameButton.icon = get_theme_icon("Edit", "EditorIcons")
	%TestStyleButton.icon = get_theme_icon("PlayCustom", "EditorIcons")
	%MakeDefaultButton.icon = get_theme_icon("Favorites", "EditorIcons")

	%InheritanceButton.get_popup().index_pressed.connect(_on_inheritance_index_pressed)

	await get_tree().process_frame
	load_style_list()


func save():
	ProjectSettings.set_setting('dialogic/layout/styles', style_list)
	ProjectSettings.set_setting('dialogic/layout/default_style', default_style)
	ProjectSettings.save()


func load_style_list() -> void:
	var latest := DialogicUtil.get_editor_setting('latest_layout_style', 'Default')
	%StyleList.clear()
	var sorted_keys := style_list.keys()
	sorted_keys.sort()
	for style_name in sorted_keys:
		%StyleList.add_item(style_name, get_theme_icon("PopupMenu", "EditorIcons"))
		if style_name == default_style:
			%StyleList.set_item_icon_modulate(%StyleList.item_count-1, get_theme_color("warning_color", "Editor"))
		if style_name == latest:
			%StyleList.select(%StyleList.item_count-1)
			_on_style_clicked(%StyleList.item_count-1)

	if !%StyleList.is_anything_selected():
		%StyleList.select(0)
		_on_style_clicked(0)


func _on_style_clicked(idx:int) -> void:
	load_style(%StyleList.get_item_text(idx))

	%RemoveButton.disabled = %StyleList.get_item_text(idx) == default_style


func _get_new_name(base_name:String) -> String:
	var new_name_idx := 2
	while base_name in style_list:
		base_name = base_name+" "+str(new_name_idx)
		new_name_idx += 1
	return base_name


func _on_add_style_index_pressed(index:int) -> void:
	# add preset style
	if index == 2:
		%StyleBrowserWindow.popup_centered_ratio(0.6)
		%StyleBrowser.current_type = 1
		%StyleBrowser.load_parts()
		var picked_info: Dictionary = await %StyleBrowserWindow.get_picked_info()
		picked_info = picked_info.duplicate(true)
		if not picked_info.is_empty():
			var undo_redo :EditorUndoRedoManager= DialogicUtil.get_dialogic_plugin().get_undo_redo()
			undo_redo.create_action('Add Premade Style', UndoRedo.MERGE_ALL)
			undo_redo.add_do_method(self, "add_style", _get_new_name(picked_info.get('name', 'New Style')), picked_info.get('data', {}))
			undo_redo.add_undo_method(self, "remove_style", _get_new_name(picked_info.get('name', 'New Style')))
			undo_redo.commit_action()

	if index == 3:
		if %StyleList.get_selected_items().is_empty():
			return
		var new_style_info := {'inherits':current_style, 'layers':[]}
		for layer in style_list[current_style].get('layers', []):
			new_style_info.layers.append({'scene_path':layer.get('scene_path', '')})
		var undo_redo :EditorUndoRedoManager= DialogicUtil.get_dialogic_plugin().get_undo_redo()
		undo_redo.create_action('Add Inherited Style', UndoRedo.MERGE_ALL)
		undo_redo.add_do_method(self, "add_style", _get_new_name(current_style+"Variation"), new_style_info)
		undo_redo.add_undo_method(self, "remove_style", _get_new_name(current_style+"Variation"))
		undo_redo.commit_action()

	if index == 4:
		var undo_redo :EditorUndoRedoManager= DialogicUtil.get_dialogic_plugin().get_undo_redo()
		undo_redo.create_action('Add Custom Style', UndoRedo.MERGE_ALL)
		undo_redo.add_do_method(self, "add_style", _get_new_name('New Style'))
		undo_redo.add_undo_method(self, "remove_style", _get_new_name('New Style'))
		undo_redo.commit_action()


func add_style(style_name:String, style_info:={}) -> void:
	style_list[style_name] = style_info
	DialogicUtil.set_editor_setting('latest_layout_style', style_name)
	save()
	load_style_list()


func remove_style(style_name:String) -> void:
	for style in style_list:
		if style_list[style].get('inherits', '') == style_name:
			realize_style_inheritance(style)
			push_warning('[Dialogic] Style "',style,'" had to be realized because it inherited "', style_name,'" which was deleted!')
	style_list.erase(style_name)
	save()
	load_style_list()


func _on_inheritance_index_pressed(index:int) -> void:
	if index == 0:
		realize_style_inheritance(current_style)


func _on_duplicate_button_pressed():
	if !%StyleList.is_anything_selected():
		return
	var undo_redo :EditorUndoRedoManager= DialogicUtil.get_dialogic_plugin().get_undo_redo()
	undo_redo.create_action('Add Style', UndoRedo.MERGE_ALL)
	undo_redo.add_do_method(self, "add_style", _get_new_name(current_style+' Copy'), style_list[current_style].duplicate(true))
	undo_redo.add_undo_method(self, "remove_style", _get_new_name(current_style+' Copy'))
	undo_redo.commit_action()


func _on_remove_button_pressed():
	if !%StyleList.is_anything_selected():
		return

	if current_style == default_style:
		push_warning("[Dialogic] You cannot delete the default style!")
		return

	var undo_redo :EditorUndoRedoManager= DialogicUtil.get_dialogic_plugin().get_undo_redo()
	undo_redo.create_action('Remove Style', UndoRedo.MERGE_ALL)
	undo_redo.add_do_method(self, "remove_style", current_style)
	undo_redo.add_undo_method(self, "add_style", current_style, style_list[current_style])
	undo_redo.commit_action()


func _on_edit_name_button_pressed():
	%LayoutStyleName.grab_focus()
	%LayoutStyleName.select_all()


func _on_layout_style_name_text_submitted(new_text:String) -> void:
	_on_layout_style_name_focus_exited()


func _on_layout_style_name_focus_exited():
	var new_name :String= %LayoutStyleName.text.strip_edges()
	if new_name in style_list:
		%LayoutStyleName.text = current_style
		return

	if current_style == default_style:
		default_style = new_name
	for style in style_list:
		if style_list[style].get('inherits', '') == current_style:
			style_list[style]['inherits'] = new_name
	style_list[new_name] = style_list[current_style].duplicate(true)
	style_list.erase(current_style)
	DialogicUtil.set_editor_setting('latest_layout_style', new_name)
	save()
	load_style_list()


func _on_make_default_button_pressed():
	default_style = current_style
	save()
	load_style_list()


func _on_test_style_button_pressed():
	var dialogic_plugin = DialogicUtil.get_dialogic_plugin()

	# Save the current opened timeline
	DialogicUtil.set_editor_setting('current_test_style', current_style)

	DialogicUtil.get_dialogic_plugin().get_editor_interface().play_custom_scene("res://addons/dialogic/Editor/TimelineEditor/test_timeline_scene.tscn")
	await get_tree().create_timer(3).timeout
	DialogicUtil.set_editor_setting('current_test_style', '')

##				STYLE SETTINGS FUNCTIONALITY
################################################################################

func load_style(style_name:String) -> void:
	current_style = style_name
	%LayoutStyleName.text = style_name
	if current_style == default_style:
		%MakeDefaultButton.tooltip_text = "Is Default"
		%MakeDefaultButton.disabled = true
	else:
		%MakeDefaultButton.tooltip_text = "Make Default"
		%MakeDefaultButton.disabled = false

	var info :Dictionary= style_list.get(style_name, {})
	%StyleEditor.load_style(style_name, info)

	%InheritanceButton.visible = not info.get('inherits', '').is_empty()
	if %InheritanceButton.visible:
		%InheritanceButton.text = "Inherits "+info.get('inherits')

	DialogicUtil.set_editor_setting('latest_layout_style', style_name)
	%StyleEditor.show()


func realize_style_inheritance(style_name:String) -> void:
	style_list[style_name] = DialogicUtil.get_inherited_style_info(style_name)
	style_list[style_name]['inherits'] = ''
	save()
	load_style_list()


func _on_style_editor_style_changed(new_style_info: Variant) -> void:
	style_list[current_style] = new_style_info
	save()
