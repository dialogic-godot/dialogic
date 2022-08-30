@tool
extends ScrollContainer

var selected_item :TreeItem = null

func _ready():
	get_parent().set_tab_icon(get_index(), get_theme_icon('Image', 'EditorIcons'))
	%ImagePicker.file_filter = "*.png, *.svg"
	%ImagePicker.resource_icon = get_theme_icon('Image', 'EditorIcons')

func load_portrait_data(item:TreeItem, data:Dictionary) -> void:
	if !data.get('scene', '').is_empty():
		get_parent().set_tab_hidden(get_index(), true)
		while get_parent().is_tab_hidden(get_parent().current_tab):
			get_parent().current_tab = (get_parent().current_tab+1)%get_parent().get_tab_count()
	else:
		get_parent().set_tab_hidden(get_index(), false)
	
	selected_item = item
	%ImagePicker.set_value(data.get('image', ''))

func _on_image_picker_value_changed(prop_name:String, value:String):
	var data:Dictionary = selected_item.get_metadata(0)
	data['image'] = value
	find_parent('CharacterEditor').update_preview()
