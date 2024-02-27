@tool
## Tab that allows setting a custom scene for a portrait.
extends DialogicCharacterEditorPortraitSection

const LAYERED_PORTRAIT_SCENE: String = "res://addons/dialogic/Modules/Character/LayeredPortrait/layered_portrait.tscn"

func _get_title() -> String:
	return "Scene"


func _init() -> void:
	hint_text = "You can use a custom scene for this portrait."


func _ready() -> void:
	%ScenePicker.file_filter = "*.tscn, *.scn; Scenes"
	%ScenePicker.resource_icon = get_theme_icon("PackedScene", "EditorIcons")
	%ScenePicker.placeholder = "Default scene"
	%ScenePicker.value_changed.connect(_on_scene_picker_value_changed)

	%OpenSceneButton.icon = get_theme_icon("ExternalLink", "EditorIcons")
	%OpenSceneButton.pressed.connect(_on_open_scene_button_pressed)

	%MakeCustomButton.icon = get_theme_icon("ActionCopy", "EditorIcons")
	%MakeCustomLayeredPortraitButton.pressed.connect(_on_make_custom_button_pressed)

	%PortraitDefaultOptions.item_selected.connect(_on_default_options_item_selected)


func _load_portrait_data(data:Dictionary) -> void:
	%ScenePicker.set_value(data.get("scene", ""))
	%OpenSceneButton.visible = !data.get("scene", "").is_empty()


func _on_default_options_item_selected(index: int) -> void:
	match index:
		0:
			if not %ScenePicker.current_value.is_empty():
				%ScenePicker.current_value = ""

			%ScenePicker.visible = false
			%MakeCustomLayeredPortraitButton.hide()

		1:
			%ScenePicker.current_value = LAYERED_PORTRAIT_SCENE
			%ScenePicker.visible = false
			%MakeCustomLayeredPortraitButton.show()

		2:
			%ScenePicker.visible = true
			%MakeCustomLayeredPortraitButton.hide()

	update_preview.emit()
	changed.emit()


func _on_scene_picker_value_changed(_prop_name: String, value: String) -> void:
	var data:Dictionary = selected_item.get_metadata(0)
	data["scene"] = value
	update_preview.emit()
	changed.emit()
	%OpenSceneButton.visible = !data.get("scene", "").is_empty()

	if value.is_empty():
		%PortraitDefaultOptions.select(0)

	elif value == LAYERED_PORTRAIT_SCENE:
		%PortraitDefaultOptions.select(1)

	else:
		%PortraitDefaultOptions.select(2)

	var selected: int = %PortraitDefaultOptions.selected
	_on_default_options_item_selected(selected)


func _on_open_scene_button_pressed() -> void:
	var current_value: String = %ScenePicker.current_value

	if not current_value.is_empty() and FileAccess.file_exists(current_value):
		DialogicUtil.get_dialogic_plugin().get_editor_interface().open_scene_from_path(%ScenePicker.current_value)
		EditorInterface.set_main_screen_editor("2D")


func _on_make_custom_button_pressed() -> void:
	find_parent("EditorView").godot_file_dialog(
		_on_make_custom_layer_file_selected,
		"",
		EditorFileDialog.FILE_MODE_OPEN_DIR,
		"Select folder for a new copy of portrait scene")


func _on_make_custom_layer_file_selected(target_path: String) -> void:
	var original_file: String = %ScenePicker.current_value
	make_scene_custom(original_file, target_path)


func make_scene_custom(previous_file: String, target_path: String) -> void:

	if not ResourceLoader.exists(previous_file):
		printerr("[Dialogic] Unable to copy portrait scene from the invalid path:" + previous_file)
		return

	var target_file := "custom_" + previous_file.get_file()
	var target_file_path := target_path.path_join(target_file)


	DirAccess.make_dir_absolute(target_path)
	DirAccess.copy_absolute(previous_file, target_file_path)

	var file := FileAccess.open(target_file_path, FileAccess.READ)
	var scene_text := file.get_as_text()
	file.close()

	file = FileAccess.open(target_file_path, FileAccess.WRITE)
	file.store_string(scene_text)
	file.close()

	%ScenePicker._set_value(target_file_path)

	find_parent("EditorView").plugin_reference.get_editor_interface().get_resource_filesystem().scan_sources()
