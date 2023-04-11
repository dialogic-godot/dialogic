@tool
extends DialogicCharacterEditorPortraitSettingsTab

## Tab that allows setting an image file on a portrait. 


func _ready() -> void:
	get_parent().set_tab_icon(get_index(), get_theme_icon('Image', 'EditorIcons'))
	%ImagePicker.file_filter = "*.png, *.svg"
	%ImagePicker.resource_icon = get_theme_icon('Image', 'EditorIcons')


func _load_portrait_data(data:Dictionary) -> void:
	# hides/shows this tab based on the scene value of this portrait
	# (only shown if the default scene is used) 
	get_parent().set_tab_hidden(get_index(), !data.get('scene', '').is_empty())
	
	%ImagePicker.set_value(data.get('image', ''))


func _on_image_picker_value_changed(prop_name:String, value:String):
	var data:Dictionary = selected_item.get_metadata(0)
	data['image'] = value
	changed.emit()
	update_preview.emit()
