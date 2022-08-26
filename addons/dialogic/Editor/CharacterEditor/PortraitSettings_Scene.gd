@tool
extends ScrollContainer

var selected_item :TreeItem = null

func _ready():
	get_parent().set_tab_icon(get_index(), get_theme_icon('PackedScene', 'EditorIcons'))
	%ScenePicker.file_filter = "*.tscn"
	%ScenePicker.resource_icon = get_theme_icon('PackedScene', 'EditorIcons')
	%ScenePicker.placeholder = 'Default scene'

func load_portrait_data(item:TreeItem, data:Dictionary) -> void:
	selected_item = item
	%ScenePicker.set_value(data.get('scene', ''))
	%IgnoreScale.button_pressed = data.get('ignore_char_scale', false)

func _on_scene_picker_value_changed(prop_name:String, value:String):
	var data:Dictionary = selected_item.get_metadata(0)
	data['scene'] = value
	find_parent('CharacterEditor').load_selected_portrait()

func _on_ignore_scale_toggled(button_pressed):
	var data:Dictionary = selected_item.get_metadata(0)
	data['ignore_char_scale'] = button_pressed
	find_parent('CharacterEditor').load_selected_portrait()
