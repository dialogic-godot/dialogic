@tool
extends DialogicCharacterEditorPortraitSection

## Tab that allows setting a custom scene for a portrait.

func _get_title() -> String:
	return "Scene"

func _init():
	hint_text = "You can use a custom scene for this portrait."

func _ready() -> void:
	%ScenePicker.file_filter = "*.tscn, *.scn; Scenes"
	%ScenePicker.resource_icon = get_theme_icon('PackedScene', 'EditorIcons')
	%ScenePicker.placeholder = 'Default scene'

	%OpenSceneButton.icon = get_theme_icon("ExternalLink", "EditorIcons")


func _load_portrait_data(data:Dictionary) -> void:
	%ScenePicker.set_value(data.get('scene', ''))
	%OpenSceneButton.visible = !data.get('scene', '').is_empty()


func _on_scene_picker_value_changed(prop_name:String, value:String) -> void:
	var data:Dictionary = selected_item.get_metadata(0)
	data['scene'] = value
	update_preview.emit()
	changed.emit()
	%OpenSceneButton.visible = !data.get('scene', '').is_empty()


func _on_open_scene_button_pressed():
	if !%ScenePicker.current_value.is_empty() and ResourceLoader.exists(%ScenePicker.current_value):
		DialogicUtil.get_dialogic_plugin().get_editor_interface().open_scene_from_path(%ScenePicker.current_value)
		EditorInterface.set_main_screen_editor("2D")
