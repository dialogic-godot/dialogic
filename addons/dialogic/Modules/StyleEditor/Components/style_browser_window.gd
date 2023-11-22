@tool
extends Window

var info := {}
signal part_selected(info:Dictionary)


func _on_close_requested() -> void:
	info = {}
	part_selected.emit({})
	hide()


func get_picked_info() -> Dictionary:
	await part_selected
	return info


func _on_style_browser_activate_part(part_info: Dictionary) -> void:
	info = part_info
	part_selected.emit(part_info)
	hide()
