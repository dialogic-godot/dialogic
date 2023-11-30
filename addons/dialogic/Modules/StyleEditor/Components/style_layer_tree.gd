@tool
extends Tree

## Script that handles drag and drop on the layer tree.


signal layer_moved(from:int, to:int)

#region DRAG AND DROP
################################################################################

func _get_drag_data(position:Vector2) -> Variant:
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


func _can_drop_data(position:Vector2, data:Variant) -> bool:
	return data is TreeItem


func _drop_data(position:Vector2, item:Variant) -> void:
	var to_item := get_item_at_position(position)
	var drop_section := get_drop_section_at_position(position)

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
