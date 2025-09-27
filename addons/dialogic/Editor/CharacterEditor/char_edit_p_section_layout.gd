@tool
extends DialogicCharacterEditorPortraitSection

## Tab that allows setting size, offset and mirror of a portrait.


func _get_title() -> String:
	return "Scale, Offset & Mirror"


func _load_portrait_data(data:Dictionary) -> void:
	%IgnoreScale.set_pressed_no_signal(data.get('ignore_char_scale', false))
	%PortraitScale.set_value(data.get('scale', 1.0)*100)
	%PortraitOffset.set_value(data.get('offset', Vector2()))
	%PortraitOffset._load_display_info({'step':1})
	%PortraitMirror.set_pressed_no_signal(data.get('mirror', false))


func _on_portrait_scale_value_changed(_property:String, value:float) -> void:
	var data: Dictionary = selected_item.get_metadata(0)
	data['scale'] = value/100.0
	update_preview.emit()
	changed.emit()


func _on_portrait_mirror_toggled(button_pressed:bool)-> void:
	var data: Dictionary = selected_item.get_metadata(0)
	data['mirror'] = button_pressed
	update_preview.emit()
	changed.emit()


func _on_ignore_scale_toggled(button_pressed:bool) -> void:
	var data: Dictionary = selected_item.get_metadata(0)
	data['ignore_char_scale'] = button_pressed
	update_preview.emit()
	changed.emit()


func _on_portrait_offset_value_changed(_property:String, value:Vector2) -> void:
	var data: Dictionary = selected_item.get_metadata(0)
	data['offset'] = value
	update_preview.emit()
	changed.emit()
