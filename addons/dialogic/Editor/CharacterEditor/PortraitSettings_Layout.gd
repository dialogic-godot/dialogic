@tool
extends ScrollContainer

var selected_item :TreeItem = null

func _ready():
	get_parent().set_tab_icon(get_index(), get_theme_icon('EditorPivot', 'EditorIcons'))

func load_portrait_data(item:TreeItem, data:Dictionary) -> void:
	selected_item = item
	%PortraitScale.value = data.get('scale', 1.0)*100
	%PortraitOffsetX.value = data.get('offset', Vector2()).x
	%PortraitOffsetY.value = data.get('offset', Vector2()).y
	%PortraitMirror.button_pressed = data.get('mirror', false)

func _on_portrait_scale_value_changed(value):
	var data:Dictionary = selected_item.get_metadata(0)
	data['scale'] = value/100.0
	find_parent('CharacterEditor').update_preview()

func _on_portrait_offset_x_value_changed(value):
	var data:Dictionary = selected_item.get_metadata(0)
	data['offset'] = data.get('offset', Vector2())
	data['offset'].x = value
	find_parent('CharacterEditor').update_preview()

func _on_portrait_offset_y_value_changed(value):
	var data:Dictionary = selected_item.get_metadata(0)
	data['offset'] = data.get('offset', Vector2())
	data['offset'].y = value
	find_parent('CharacterEditor').update_preview()

func _on_portrait_mirror_toggled(button_pressed):
	var data:Dictionary = selected_item.get_metadata(0)
	data['mirror'] = button_pressed
	find_parent('CharacterEditor').update_preview()
