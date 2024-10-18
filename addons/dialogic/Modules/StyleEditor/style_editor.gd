@tool
extends DialogicEditor

## Editor that handles the editing of styles and their layers.


var styles: Array[DialogicStyle] = []
var current_style : DialogicStyle = null
var default_style := ""

var premade_style_parts := {}

@onready var StyleList: ItemList = %StyleList

#region EDITOR MANAGEMENT
################################################################################

func _get_title() -> String:
	return "Styles"


func _get_icon() -> Texture:
	return load(DialogicUtil.get_module_path('StyleEditor').path_join("styles_icon.svg"))


func _register() -> void:
	editors_manager.register_simple_editor(self)
	alternative_text = "Change the look of the dialog in your game"


func _open(_extra_info:Variant = null) -> void:
	load_style_list()


func _close() -> void:
	save_style_list()
	save_style()


#endregion


func _ready() -> void:
	collect_styles()

	setup_ui()


#region STYLE MANAGEMENT
################################################################################

func collect_styles() -> void:
	for indexer in DialogicUtil.get_indexers():
		for layout in indexer._get_layout_parts():
			premade_style_parts[layout['path']] = layout

	var style_list: Array = ProjectSettings.get_setting('dialogic/layout/style_list', [])
	for style in style_list:
		if ResourceLoader.exists(style):
			if style != null:
				styles.append(ResourceLoader.load(style, "DialogicStyle"))
			else:
				print("[Dialogic] Failed to open style '", style, "'. Some dependency might be broken.")
		else:
			print("[Dialogic] Failed to open style '", style, "'. Might have been moved or deleted.")

	default_style = ProjectSettings.get_setting('dialogic/layout/default_style', 'Default')


func save_style_list() -> void:
	ProjectSettings.set_setting('dialogic/layout/style_list', styles.map(func(style:DialogicStyle): return style.resource_path))
	ProjectSettings.set_setting('dialogic/layout/default_style', default_style)
	ProjectSettings.save()


func save_style() -> void:
	if current_style == null:
		return

	ResourceSaver.save(current_style)


func add_style(file_path:String, style:DialogicStyle, inherits:DialogicStyle= null) -> void:
	style.resource_path = file_path
	style.inherits = inherits

	if style.layer_list.is_empty() and style.inherits_anything():
		for id in style.get_layer_inherited_list():
			style.add_layer('', {}, id)

	ResourceSaver.save(style, file_path)

	styles.append(style)

	if len(styles) == 1:
		default_style = style.resource_path

	save_style_list()
	load_style_list()
	select_style(style)


func delete_style(style:DialogicStyle) -> void:
	for other_style in styles:
		if other_style.inherits == style:
			other_style.realize_inheritance()
			push_warning('[Dialogic] Style "',other_style.name,'" had to be realized because it inherited "', style.name,'" which was deleted!')

	if style.resource_path == default_style:
		default_style = ""
	styles.erase(style)
	save_style_list()


func delete_style_by_name(style_name:String) -> void:
	for style in styles:
		if style.name == style_name:
			delete_style(style)
			return


func realize_style() -> void:
	current_style.realize_inheritance()

	select_style(current_style)


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

	StyleList.item_selected.connect(_on_stylelist_selected)
	%AddButton.get_popup().index_pressed.connect(_on_AddStyleMenu_selected)
	%AddButton.about_to_popup.connect(_on_AddStyleMenu_about_to_popup)
	%InheritanceButton.get_popup().index_pressed.connect(_on_inheritance_index_pressed)
	StyleList.set_drag_forwarding(_on_stylelist_drag, _on_stylelist_can_drop, _on_style_list_drop)
	%StyleView.hide()
	%NoStyleView.show()

func load_style_list() -> void:
	var latest: String = DialogicUtil.get_editor_setting('latest_layout_style', 'Default')

	StyleList.clear()
	var idx := 0
	for style in styles:
		# TODO remove when going Beta
		style.update_from_pre_alpha16()
		StyleList.add_item(style.name, get_theme_icon("PopupMenu", "EditorIcons"))
		StyleList.set_item_tooltip(idx, style.resource_path)
		StyleList.set_item_metadata(idx, style)

		if style.resource_path == default_style:
			StyleList.set_item_icon_modulate(idx, get_theme_color("warning_color", "Editor"))
		if style.resource_path.begins_with("res://addons/dialogic"):
			StyleList.set_item_icon_modulate(idx, get_theme_color("property_color_z", "Editor"))
			StyleList.set_item_tooltip(idx, "This is a default style. Only edit it if you know what you are doing!")
			StyleList.set_item_custom_bg_color(idx, get_theme_color("property_color_z", "Editor").lerp(get_theme_color("dark_color_3", "Editor"), 0.8))
		if style.name == latest:
			StyleList.select(idx)
			load_style(style)
		idx += 1

	if len(styles) == 0:
		%StyleView.hide()
		%NoStyleView.show()

	elif !StyleList.is_anything_selected():
		StyleList.select(0)
		load_style(StyleList.get_item_metadata(0))


func _on_stylelist_selected(index:int) -> void:
	load_style(StyleList.get_item_metadata(index))


func select_style(style:DialogicStyle) -> void:
	DialogicUtil.set_editor_setting('latest_layout_style', style.name)
	for idx in range(StyleList.item_count):
		if StyleList.get_item_metadata(idx) == style:
			StyleList.select(idx)
			return


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

	%StyleEditor.load_style(style)

	%InheritanceButton.visible = style.inherits_anything()
	if %InheritanceButton.visible:
		%InheritanceButton.text = "Inherits " + style.inherits.name


	DialogicUtil.set_editor_setting('latest_layout_style', style.name)

	%StyleView.show()
	%NoStyleView.hide()


func _on_AddStyleMenu_about_to_popup() -> void:
	%AddButton.get_popup().set_item_disabled(3, not StyleList.is_anything_selected())


func _on_AddStyleMenu_selected(index:int) -> void:
	# add preset style
	if index == 2:
		%StyleBrowserWindow.popup_centered_ratio(0.6)
		%StyleBrowser.current_type = 1
		%StyleBrowser.load_parts()
		var picked_info: Dictionary = await %StyleBrowserWindow.get_picked_info()
		if not picked_info.has('style_path'):
			return

		if not ResourceLoader.exists(picked_info.style_path):
			return

		var new_style: DialogicStyle = load(picked_info.style_path).clone()

		find_parent('EditorView').godot_file_dialog(
			add_style_undoable.bind(new_style),
			'*.tres',
			EditorFileDialog.FILE_MODE_SAVE_FILE,
			"Select folder for new style")

	if index == 3:
		if StyleList.get_selected_items().is_empty():
			return
		find_parent('EditorView').godot_file_dialog(
			add_style_undoable.bind(DialogicStyle.new(), current_style),
			'*.tres',
			EditorFileDialog.FILE_MODE_SAVE_FILE,
			"Select folder for new style")

	if index == 4:
		find_parent('EditorView').godot_file_dialog(
			add_style_undoable.bind(DialogicStyle.new()),
			'*.tres',
			EditorFileDialog.FILE_MODE_SAVE_FILE,
			"Select folder for new style")


func add_style_undoable(file_path:String, style:DialogicStyle, inherits:DialogicStyle = null) -> void:
	style.name = _get_new_name(file_path.get_file().trim_suffix('.'+file_path.get_extension()))
	var undo_redo: EditorUndoRedoManager = DialogicUtil.get_dialogic_plugin().get_undo_redo()
	undo_redo.create_action('Add Style', UndoRedo.MERGE_ALL)
	undo_redo.add_do_method(self, "add_style", file_path, style, inherits)
	undo_redo.add_do_method(self, "load_style_list")
	undo_redo.add_undo_method(self, "delete_style", style)
	undo_redo.add_undo_method(self, "load_style_list")
	undo_redo.commit_action()
	DialogicUtil.set_editor_setting('latest_layout_style', style.name)


func _on_duplicate_button_pressed() -> void:
	if !StyleList.is_anything_selected():
		return
	find_parent('EditorView').godot_file_dialog(
		add_style_undoable.bind(current_style.clone(), null),
		'*.tres',
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		"Select folder for new style")


func _on_remove_button_pressed() -> void:
	if !StyleList.is_anything_selected():
		return

	if current_style.name == default_style:
		push_warning("[Dialogic] You cannot delete the default style!")
		return

	delete_style(current_style)
	load_style_list()


func _on_edit_name_button_pressed() -> void:
	%LayoutStyleName.grab_focus()
	%LayoutStyleName.select_all()


func _on_layout_style_name_text_submitted(_new_text:String) -> void:
	_on_layout_style_name_focus_exited()


func _on_layout_style_name_focus_exited() -> void:
	var new_name: String = %LayoutStyleName.text.strip_edges()
	if new_name == current_style.name:
		return

	for style in styles:
		if style.name == new_name:
			%LayoutStyleName.text = current_style.name
			return

	current_style.name = new_name
	DialogicUtil.set_editor_setting('latest_layout_style', new_name)
	load_style_list()


func _on_make_default_button_pressed() -> void:
	default_style = current_style.resource_path
	save_style_list()
	load_style_list()



func _on_test_style_button_pressed() -> void:
	var dialogic_plugin := DialogicUtil.get_dialogic_plugin()

	# Save the current opened timeline
	DialogicUtil.set_editor_setting('current_test_style', current_style.name)

	DialogicUtil.get_dialogic_plugin().get_editor_interface().play_custom_scene("res://addons/dialogic/Editor/TimelineEditor/test_timeline_scene.tscn")
	await get_tree().create_timer(3).timeout
	DialogicUtil.set_editor_setting('current_test_style', '')


func _on_inheritance_index_pressed(index:int) -> void:
	if index == 0:
		realize_style()



func _on_start_styling_button_pressed() -> void:
	var new_style := DialogicUtil.get_fallback_style().clone()

	find_parent('EditorView').godot_file_dialog(
		add_style_undoable.bind(new_style),
		'*.tres',
		EditorFileDialog.FILE_MODE_SAVE_FILE,
		"Select folder for new style")


#endregion

func _on_stylelist_drag(vector:Vector2) -> Variant:
	return null


func _on_stylelist_can_drop(at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	if not data.get('type', 's') == 'files':
		return false
	for f in data.files:
		var style := load(f)
		if style is DialogicStyle:
			if not style in styles:
				return true

	return false

func _on_style_list_drop(at_position: Vector2, data: Variant) -> void:
	for file in data.files:
		var style := load(file)
		if style is DialogicStyle:
			if not style in styles:
				styles.append(style)
	save_style_list()
	load_style_list()


#region Helpers
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
