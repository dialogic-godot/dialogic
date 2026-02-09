@tool
extends DialogicEditor

## Editor that handles the editing of styles and their layers.

var unre := UndoRedo.new()


var styles: Array[DialogicStyle] = []
var current_style : DialogicStyle = null
var default_style := ""


#region EDITOR MANAGEMENT
################################################################################

func _get_title() -> String:
	return "Styles"


func _get_icon() -> Texture:
	return load(DialogicUtil.get_module_path("StyleEditor").path_join("styles_icon.svg"))


func _register() -> void:
	editors_manager.register_simple_editor(self)
	alternative_text = "Change the look of the dialog in your game"


func _open(_extra_info:Variant = null) -> void:
	%StyleList.load_style_list(styles)


func _close() -> void:
	save_style_list()
	save_style()


#endregion


func _ready() -> void:
	if get_parent() is SubViewport:
		return

	collect_styles()
	setup_ui()

	unre.version_changed.connect(_on_unre_version_changed)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if EditorInterface.get_editor_settings().get_shortcut("ui_undo").matches_event(event) and event.is_pressed():
		unre.undo()
		accept_event()
	elif EditorInterface.get_editor_settings().get_shortcut("ui_redo").matches_event(event) and event.is_pressed():
		unre.redo()
		accept_event()



#region STYLE MANAGEMENT METHODS
################################################################################

## Lists all styles and style parts
func collect_styles() -> void:
	var style_list: Array = ProjectSettings.get_setting("dialogic/layout/style_list", [])
	for style in style_list:
		if ResourceLoader.exists(style):
			if style != null:
				styles.append(ResourceLoader.load(style, "DialogicStyle"))
			else:
				print("[Dialogic] Failed to open style '", style, "'. Some dependency might be broken.")
		else:
			print("[Dialogic] Failed to open style '", style, "'. Might have been moved or deleted.")

	default_style = ProjectSettings.get_setting("dialogic/layout/default_style", "Default")



func save_style() -> void:
	if current_style == null:
		return

	ResourceSaver.save(current_style)


func create_style(file_path:String, style:DialogicStyle, inherits:DialogicStyle = null) -> void:
	style.resource_path = file_path
	style.inherits = inherits

	if style.layer_list.is_empty() and style.inherits_anything():
		for id in style.get_layer_inherited_list():
			style.add_layer("", {}, id)

	ResourceSaver.save(style, file_path)


## TODO: Make this undoable
func realize_style() -> void:
	current_style.realize_inheritance()
	#%StyleList.select_style(current_style)
	%StyleList.load_style_list()


#endregion


#region STYLE LIST MANAGEMENT METHODS
################################################################################

func save_style_list() -> void:
	ProjectSettings.set_setting("dialogic/layout/style_list", styles.map(func(style:DialogicStyle): return style.resource_path))
	ProjectSettings.set_setting("dialogic/layout/default_style", default_style)
	ProjectSettings.save()


func create_and_add_new_style(file_path:String, style:DialogicStyle, inherits:DialogicStyle = null) -> void:
	style.name = _get_new_name(file_path.get_file().trim_suffix("."+file_path.get_extension()).capitalize())
	create_style(file_path, style, inherits)
	add_style_to_list(style)


func add_style_to_list(style:DialogicStyle) -> void:
	var new_list := styles.duplicate()
	new_list.append(style)
	set_style_list_undoable(new_list)


func remove_from_style_list(style:DialogicStyle) -> void:
	var new_list := styles.duplicate()
	new_list.erase(style)
	set_style_list_undoable(new_list)


func set_style_list_undoable(list:Array) -> void:
	unre.create_action("Add Style To List")
	unre.add_do_method(set_latest_style.bind(get_latest_style()))
	unre.add_do_method(set_style_list.bind(list))
	unre.add_undo_method(set_latest_style.bind(get_latest_style()))
	unre.add_undo_method(set_style_list.bind(styles.duplicate()))
	unre.commit_action()


func set_style_list(list:Array) -> void:
	styles = list
	save_style_list()
	%StyleList.load_style_list(styles)


func set_latest_style(style_name:String) -> void:
	DialogicUtil.set_editor_setting("latest_layout_style", style_name)


func get_latest_style() -> String:
	return DialogicUtil.get_editor_setting("latest_layout_style", "Default")

#endregion


#region USER INTERFACE
################################################################################

func setup_ui() -> void:
	%AddButton.icon = get_theme_icon("Add", "EditorIcons")
	%DuplicateButton.icon = get_theme_icon("Duplicate", "EditorIcons")
	%InheritanceButton.icon = get_theme_icon("GuiDropdown", "EditorIcons")
	%RemoveButton.icon = get_theme_icon("Remove", "EditorIcons")

	%EditNameButton.icon = get_theme_icon("Edit", "EditorIcons")
	%TestStyleButton.icon = get_theme_icon("PlayCustom", "EditorIcons")
	%MakeDefaultButton.icon = get_theme_icon("Favorites", "EditorIcons")

	%AddButton.get_popup().index_pressed.connect(_on_AddStyleMenu_selected)
	%AddButton.about_to_popup.connect(_on_AddStyleMenu_about_to_popup)
	%InheritanceButton.get_popup().index_pressed.connect(_on_inheritance_index_pressed)

	%StyleView.hide()
	%StyleListSection.hide()
	%NoStyleView.show()


func change_style(style:DialogicStyle) -> void:
	print("WOWIE")
	unre.create_action("Change Style", UndoRedo.MERGE_ALL)
	unre.add_do_method(load_style.bind(style))
	unre.add_undo_method(load_style.bind(current_style))
	unre.commit_action()


func load_style(style:DialogicStyle) -> void:
	if current_style != null:
		current_style.changed.disconnect(save_style)

	save_style()
	current_style = style
	if current_style == null:
		return
	current_style.changed.connect(save_style)

	%LayoutStyleName.text = style.name
	if style.resource_path == default_style:
		%MakeDefaultButton.tooltip_text = "Is Default"
		%MakeDefaultButton.disabled = true
	else:
		%MakeDefaultButton.tooltip_text = "Make Default"
		%MakeDefaultButton.disabled = false

	%LayerEditor.load_style(style)

	%InheritanceButton.visible = style.inherits_anything()
	if %InheritanceButton.visible:
		%InheritanceButton.text = "Inherits " + style.inherits.name

	set_latest_style(style.name)
	%StyleList.select_style(style, true)

	%StyleView.show()
	%StyleListSection.show()
	%NoStyleView.hide()

#endregion


#region ADD STYLE MENU
################################################################################

func _on_AddStyleMenu_about_to_popup() -> void:
	%AddButton.get_popup().set_item_disabled(3, not %StyleList.get_selected())


func _on_AddStyleMenu_selected(index:int) -> void:
	# add preset style
	if index == 2:
		%StyleBrowserWindow.popup_centered_ratio(0.6)
		%StyleBrowser.current_type = 1
		%StyleBrowser.load_parts()
		var picked_info: Dictionary = await %StyleBrowserWindow.get_picked_info()
		if not picked_info.has("style_path"):
			return

		if not ResourceLoader.exists(picked_info.style_path):
			return

		var new_style: DialogicStyle = load(picked_info.style_path).clone()

		find_parent("EditorView").godot_file_dialog(
			create_and_add_new_style.bind(new_style),
			"*.tres",
			EditorFileDialog.FILE_MODE_SAVE_FILE,
			"Select folder for new style")

	if index == 3:
		if not %StyleList.get_selected():
			return
		find_parent("EditorView").godot_file_dialog(
			create_and_add_new_style.bind(DialogicStyle.new(), current_style),
			"*.tres",
			EditorFileDialog.FILE_MODE_SAVE_FILE,
			"Select folder for new style")

	if index == 4:
		find_parent("EditorView").godot_file_dialog(
			create_and_add_new_style.bind(DialogicStyle.new()),
			"*.tres",
			EditorFileDialog.FILE_MODE_SAVE_FILE,
			"Select folder for new style")

#endregion


#region DUPLICATE
################################################################################

func _on_duplicate_button_pressed() -> void:
	if not %StyleList.get_selected():
		return
	find_parent('EditorView').godot_file_dialog(
		create_and_add_new_style.bind(current_style.clone(), null),
		'*.tres',
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		"Select folder for new style")

#endregion


#region REMOVE STYLE FROM LIST
################################################################################

func _on_remove_button_pressed() -> void:
	if not %StyleList.get_selected():
		return

	if current_style.name == default_style:
		push_warning("[Dialogic] You cannot delete the default style!")
		return

	remove_from_style_list(current_style)

#endregion


#region DEFAULT STYLE
################################################################################

func make_current_default() -> void:
	if default_style == current_style.resource_path: return

	unre.create_action("Make Style Default")
	unre.add_do_method(make_style_default.bind(current_style.resource_path))
	unre.add_undo_method(make_style_default.bind(default_style))
	unre.commit_action()


func make_style_default(style_path:String) -> void:
	default_style = style_path
	save_style_list()
	%StyleList.load_style_list(styles)

#endregion


#region STYLE NAME
################################################################################

func _on_style_list_rename_style(style: DialogicStyle, new_name: String) -> void:
	unre.create_action("Rename Style")
	unre.add_do_method(set_style_name.bind(style, new_name))
	unre.add_undo_method(set_style_name.bind(style, style.name))
	unre.commit_action()


func set_style_name(style:DialogicStyle, style_name:String) -> void:
	if style.name == get_latest_style():
		set_latest_style(style_name)
	style.name = style_name
	%StyleList.load_style_list(styles)

#endregion


#region TESTS STYLE
################################################################################

func _on_test_style_button_pressed() -> void:
	# Save the current opened timeline
	DialogicUtil.set_editor_setting("current_test_style", current_style.name)

	EditorInterface.play_custom_scene("res://addons/dialogic/Editor/TimelineEditor/test_timeline_scene.tscn")
	await get_tree().create_timer(3).timeout
	DialogicUtil.set_editor_setting("current_test_style", "")

#endregion



func _on_inheritance_index_pressed(index:int) -> void:
	if index == 0:
		realize_style()


#region NO STYLE VIEW
################################################################################

func _on_start_styling_button_pressed() -> void:
	_on_AddStyleMenu_selected(2)

#endregion


#region HELPERS
################################################################################

func _get_new_name(base_name:String) -> String:
	var new_name_idx := 1
	var found_unique_name := false
	var new_name := base_name
	while not found_unique_name:
		found_unique_name = true
		for style in styles:
			if style.name == new_name:
				new_name_idx += 1
				new_name = base_name+" "+str(new_name_idx)
				found_unique_name = false
	return new_name

#endregion


func _on_unre_version_changed() -> void:
	#printt(unre.get_current_action(), unre.get_current_action_name())
	pass
