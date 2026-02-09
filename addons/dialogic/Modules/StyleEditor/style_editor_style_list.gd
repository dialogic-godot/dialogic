@tool
extends Tree

enum RightClickMenuItems {RENAME, DUPLICATE, DELETE, CLEAR_INHERITANCE, MAKE_DEFAULT, SHOW_IN_FILESYSTEM}

signal load_style(style:DialogicStyle)
signal rename_style(style:DialogicStyle, new_name:String)

func _ready() -> void:
	if owner.get_parent() is SubViewport:
		return

	%StyleListRightClickMenu.clear()
	%StyleListRightClickMenu.add_icon_item(get_theme_icon("Rename", "EditorIcons"), "Rename", RightClickMenuItems.RENAME)
	%StyleListRightClickMenu.add_icon_item(get_theme_icon("Duplicate", "EditorIcons"), "Duplicate", RightClickMenuItems.DUPLICATE)
	%StyleListRightClickMenu.add_icon_item(get_theme_icon("Remove", "EditorIcons"), "Delete", RightClickMenuItems.DELETE)
	%StyleListRightClickMenu.add_separator()
	%StyleListRightClickMenu.add_icon_item(get_theme_icon("Favorites", "EditorIcons"), "Make Default",  RightClickMenuItems.MAKE_DEFAULT)
	%StyleListRightClickMenu.add_separator()
	%StyleListRightClickMenu.add_icon_item(get_theme_icon("Filesystem", "EditorIcons"), "Show in FileSystem",  RightClickMenuItems.SHOW_IN_FILESYSTEM)



func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		%StyleListRightClickMenu.popup_on_parent(Rect2(get_global_mouse_position(),Vector2()))
		%StyleListRightClickMenu.set_meta("item", get_item_at_position(mouse_position))


func load_style_list(styles:Array[DialogicStyle]) -> void:
	var latest: String = owner.get_latest_style()

	clear()
	create_item()
	var style_to_item_map := {}
	for style in styles:
		## TODO remove when going Beta
		#style.update_from_pre_alpha16()
		var item := create_item()
		item.set_text(0, style.name)
		item.set_icon(0, get_theme_icon("PopupMenu", "EditorIcons"))
		item.set_tooltip_text(0, style.resource_path)
		item.set_metadata(0, style)
		item.set_editable(0, true)

		if style.resource_path == owner.default_style:
			item.set_icon_modulate(0, get_theme_color("warning_color", "Editor"))
		if style.resource_path.begins_with("res://addons/dialogic"):
			item.set_icon_modulate(0, get_theme_color("property_color_z", "Editor"))
			item.set_tooltip_text(0, "This is a default style. Only edit it if you know what you are doing!")
			item.set_custom_bg_color(0, get_theme_color("property_color_z", "Editor").lerp(get_theme_color("dark_color_3", "Editor"), 0.8))
		if style.name == latest:
			item.select(0)
			load_style.emit(style)

		style_to_item_map[style] = item

	begin_bulk_theme_override()
	add_theme_constant_override("item_margin", 0)
	for style in styles:
		if style.inherits and style.inherits in style_to_item_map:
			style_to_item_map[style].get_parent().remove_child(style_to_item_map[style])
			style_to_item_map[style.inherits].add_child(style_to_item_map[style])
			add_theme_constant_override("item_margin", 12)
			if style.name == latest:
				style_to_item_map[style].select(0)
				load_style.emit(style)
	end_bulk_theme_override()

	if len(styles) == 0:
		%StyleView.hide()
		%NoStyleView.show()

	elif not get_selected():
		get_root().get_child(0).select(0)
		load_style.emit(get_root().get_child(0).get_metadata(0))


func select_style(style:DialogicStyle) -> void:
	DialogicUtil.set_editor_setting('latest_layout_style', style.name)
	var item := get_root()
	while item:
		if item.get_metadata(0) and item.get_metadata(0) == style:
			item.select(0)
			break
		item = item.get_next_in_tree()


func _on_item_selected() -> void:
	load_style.emit(get_selected().get_metadata(0))


func _on_item_edited() -> void:
	if get_selected().get_metadata(0).name == get_selected().get_text(0).strip_edges():
		return
	elif get_selected().get_text(0).strip_edges().is_empty():
		get_selected().set_text(0, get_selected().get_metadata(0).name)
		return
	rename_style.emit(get_selected().get_metadata(0), get_selected().get_text(0).strip_edges())


func _on_style_list_right_click_menu_id_pressed(id: int) -> void:
	var item: TreeItem = %StyleListRightClickMenu.get_meta("item", null)
	match id:
		RightClickMenuItems.RENAME:
			edit_selected(true)
		RightClickMenuItems.DUPLICATE:
			owner._on_duplicate_button_pressed()
		RightClickMenuItems.DELETE:
			owner._on_remove_button_pressed()
		RightClickMenuItems.MAKE_DEFAULT:
			owner.make_current_default()
		RightClickMenuItems.SHOW_IN_FILESYSTEM:
			EditorInterface.get_file_system_dock().navigate_to_path(item.get_metadata(0).resource_path)


#region DRAG AND DROP
################################################################################

func _get_drag_data(_at_position: Vector2) -> Variant:
	return null


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	if not data.get('type', 's') == 'files':
		return false
	for f in data.files:
		var style := load(f)
		if style is DialogicStyle:
			if not style in owner.styles:
				return true

	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	for file in data.files:
		var style := load(file)
		if style is DialogicStyle:
			if not style in owner.styles:
				owner.styles.append(style)
	owner.save_style_list()
	load_style_list(owner.styles)

#endregion
