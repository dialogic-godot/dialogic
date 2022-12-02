@tool
extends DialogicCharacterEditorPortraitSettingsTab

## Tab that allows setting a custom scene. 


func _ready():
	get_parent().set_tab_icon(get_index(), get_theme_icon('PackedScene', 'EditorIcons'))
	%ScenePicker.file_filter = "*.tscn"
	%ScenePicker.resource_icon = get_theme_icon('PackedScene', 'EditorIcons')
	%ScenePicker.placeholder = 'Default scene'


func _load_portrait_data(data:Dictionary) -> void:
	%ScenePicker.set_value(data.get('scene', ''))
	%IgnoreScale.button_pressed = data.get('ignore_char_scale', false)


func _on_scene_picker_value_changed(prop_name:String, value:String) -> void:
	var data:Dictionary = selected_item.get_metadata(0)
	data['scene'] = value
	update_preview.emit()
	changed.emit()


func _on_ignore_scale_toggled(button_pressed):
	var data:Dictionary = selected_item.get_metadata(0)
	data['ignore_char_scale'] = button_pressed
	update_preview.emit()
	changed.emit()
