@tool
extends DialogicCharacterEditorPortraitSettingsTab

## Tab that allows setting size, offset and mirror of a portrait. 


func _ready():
	get_parent().set_tab_icon(get_index(), get_theme_icon('EditorPivot', 'EditorIcons'))


func _load_portrait_data(data:Dictionary) -> void:
	%PortraitScale.value = data.get('scale', 1.0)*100
	%PortraitOffsetX.value = data.get('offset', Vector2()).x
	%PortraitOffsetY.value = data.get('offset', Vector2()).y
	%PortraitMirror.button_pressed = data.get('mirror', false)


func _on_portrait_scale_value_changed(value) -> void:
	var data:Dictionary = selected_item.get_metadata(0)
	data['scale'] = value/100.0
	update_preview.emit()
	changed.emit()


func _on_portrait_offset_x_value_changed(value) -> void:
	var data:Dictionary = selected_item.get_metadata(0)
	data['offset'] = data.get('offset', Vector2())
	data['offset'].x = value
	update_preview.emit()
	changed.emit()

func _on_portrait_offset_y_value_changed(value)-> void:
	var data:Dictionary = selected_item.get_metadata(0)
	data['offset'] = data.get('offset', Vector2())
	data['offset'].y = value
	update_preview.emit()
	changed.emit()

func _on_portrait_mirror_toggled(button_pressed:bool)-> void:
	var data:Dictionary = selected_item.get_metadata(0)
	data['mirror'] = button_pressed
	update_preview.emit()
	changed.emit()
