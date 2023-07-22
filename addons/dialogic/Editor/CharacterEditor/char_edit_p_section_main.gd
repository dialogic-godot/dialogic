@tool
extends DialogicCharacterEditorPortraitSection

## Tab that allows setting an image file on a portrait. 


func _ready() -> void:
	%ImagePicker.file_filter = "*.png, *.svg"
	%ImagePicker.resource_icon = get_theme_icon('Image', 'EditorIcons')
	
	%ScenePicker.file_filter = "*.tscn, *.scn; Scenes"
	%ScenePicker.resource_icon = get_theme_icon('PackedScene', 'EditorIcons')
	%ScenePicker.placeholder = 'Default scene'


func _load_portrait_data(data:Dictionary) -> void:
	%ScenePicker.set_value(data.get('scene', ''))
	%ImagePicker.set_value(data.get('image', ''))
	update_image_picker_visibility(data['scene'].is_empty())


func _on_image_picker_value_changed(prop_name:String, value:String):
	var data:Dictionary = selected_item.get_metadata(0)
	data['image'] = value
	changed.emit()
	update_preview.emit()


func _on_scene_picker_value_changed(prop_name:String, value:String) -> void:
	var data:Dictionary = selected_item.get_metadata(0)
	data['scene'] = value
	update_image_picker_visibility(data['scene'].is_empty())
	update_preview.emit()
	changed.emit()
	

func update_image_picker_visibility(show= true) -> void:
	%ImagePicker.visible = show
	%ImageLabel.visible = show
