@tool
extends Tree

## Script that handles drag and drop on the layer tree.


enum RightClickMenuItems {RENAME, DELETE, OPEN_SCENE, SHOW_IN_FILESYSTEM}

signal layer_moved(from:int, to:int)


func _ready() -> void:
	if owner.get_parent() is SubViewport:
		return

	%LayerListRightClickMenu.clear()
	%LayerListRightClickMenu.add_icon_item(get_theme_icon("Rename", "EditorIcons"), "Rename", RightClickMenuItems.RENAME)
	%LayerListRightClickMenu.add_icon_item(get_theme_icon("Remove", "EditorIcons"), "Delete", RightClickMenuItems.DELETE)
	%LayerListRightClickMenu.add_separator()
	%LayerListRightClickMenu.add_icon_item(get_theme_icon("PackedScene", "EditorIcons"), "Open Scene", RightClickMenuItems.OPEN_SCENE)
	%LayerListRightClickMenu.add_icon_item(get_theme_icon("Filesystem", "EditorIcons"), "Show in FileSystem", RightClickMenuItems.SHOW_IN_FILESYSTEM)


func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		%LayerListRightClickMenu.set_item_disabled(1, get_item_at_position(mouse_position).get_meta("id").is_empty())
		%LayerListRightClickMenu.popup_on_parent(Rect2(get_global_mouse_position(),Vector2()))
		%LayerListRightClickMenu.set_meta("item", get_item_at_position(mouse_position))


#region DRAG AND DROP
################################################################################

func _get_drag_data(_at_position:Vector2) -> Variant:
	if get_selected() == null or get_selected() == get_root():
		return

	if find_parent('StyleEditor').current_style.inherits != null:
		return

	drop_mode_flags = DROP_MODE_INBETWEEN
	var preview := Label.new()
	preview.text = "     "+get_selected().get_text(0)
	preview.add_theme_stylebox_override('normal', get_theme_stylebox("Background", "EditorStyles"))
	set_drag_preview(preview)

	return get_selected()


func _can_drop_data(_at_position:Vector2, data:Variant) -> bool:
	return data is TreeItem


func _drop_data(at_position:Vector2, item:Variant) -> void:
	var to_item := get_item_at_position(at_position)
	var drop_section := get_drop_section_at_position(at_position)

	if to_item == get_root():
		if item.get_index() != 0:
			layer_moved.emit(item.get_index(), 0)
		return

	if to_item == null:
		if item.get_index() != get_root().get_child_count()-1:
			layer_moved.emit(item.get_index(), get_root().get_child_count()-1)
		return

	var to_idx: int = to_item.get_index()+max(0, drop_section)
	if to_idx > item.get_index():
		to_idx -= 1

	if to_idx != item.get_index():
		layer_moved.emit(item.get_index(), to_idx)

#endregion


func _on_layer_list_right_click_menu_id_pressed(id: int) -> void:
	var item: TreeItem = %LayerListRightClickMenu.get_meta("item", null)
	match id:
		RightClickMenuItems.RENAME:
			edit_selected(true)
		RightClickMenuItems.DELETE:
			%LayerList.delete_layer()
		RightClickMenuItems.SHOW_IN_FILESYSTEM:
			EditorInterface.get_file_system_dock().navigate_to_path(item.get_meta("scene"))
		RightClickMenuItems.OPEN_SCENE:
			%LayerEditor.edit_layer_scene(item.get_meta("scene"))
