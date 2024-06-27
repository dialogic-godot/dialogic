@tool
extends DialogicCharacterEditorPortraitSection

## Tab that allows setting a custom scene for a portrait.

func _get_title() -> String:
	return "Scene"

func _init() -> void:
	hint_text = "You can use a custom scene for this portrait."

func _start_opened() -> bool:
	return true

func _ready() -> void:
	%ChangeSceneButton.icon = get_theme_icon("Loop", "EditorIcons")
	%ScenePicker.file_filter = "*.tscn, *.scn; Scenes"
	%ScenePicker.resource_icon = get_theme_icon('PackedScene', 'EditorIcons')
	%ScenePicker.placeholder = 'Default scene'

	%OpenSceneButton.icon = get_theme_icon("ExternalLink", "EditorIcons")


func _load_portrait_data(data:Dictionary) -> void:
	reload_ui(data)


func _on_open_scene_button_pressed() -> void:
	var data: Dictionary = selected_item.get_metadata(0)
	if ResourceLoader.exists(data.get("scene", "")):
		DialogicUtil.get_dialogic_plugin().get_editor_interface().open_scene_from_path(data.get("scene", ""))
		await get_tree().process_frame
		EditorInterface.set_main_screen_editor("2D")


func _on_change_scene_button_pressed() -> void:
	%PortraitSceneBrowserWindow.popup_centered_ratio(0.6)


func _on_portrait_scene_browser_activate_part(part_info: Dictionary) -> void:
	%PortraitSceneBrowserWindow.hide()
	match part_info.type:
		"General":
			set_scene_path(part_info.path)
		"Preset":
			find_parent("EditorView").godot_file_dialog(
				create_new_portrait_scene.bind(part_info),
				'*.tscn,*.scn',
				EditorFileDialog.FILE_MODE_SAVE_FILE,
				"Select where to save the new scene",
				part_info.path.get_file().trim_suffix("."+part_info.path.get_extension())+"_"+character_editor.current_resource.get_character_name().to_lower())
		"Custom":
			find_parent("EditorView").godot_file_dialog(
				set_scene_path,
				'*.tscn, *.scn',
				EditorFileDialog.FILE_MODE_OPEN_FILE,
				"Select custom portrait scene",)
		"Default":
			set_scene_path("")


func create_new_portrait_scene(target_file: String, info: Dictionary) -> void:
	var path := make_portrait_preset_custom(target_file, info)
	set_scene_path(path)


func make_portrait_preset_custom(target_file:String, info: Dictionary) -> String:
	var previous_file: String = info.path

	var target_folder := target_file.get_base_dir()
	target_file = target_file.get_file()

	DirAccess.make_dir_absolute(target_folder)

	DirAccess.copy_absolute(previous_file, target_folder.path_join(target_file))

	var file := FileAccess.open(target_folder.path_join(target_file), FileAccess.READ)
	var scene_text := file.get_as_text()
	file.close()
	if scene_text.begins_with('[gd_scene'):
		var base_path: String = previous_file.get_base_dir()

		var result := RegEx.create_from_string("\\Q\""+base_path+"\\E(?<file>[^\"]*)\"").search(scene_text)
		while result:
			DirAccess.copy_absolute(base_path.path_join(result.get_string('file')), target_folder.path_join(result.get_string('file')))
			scene_text = scene_text.replace(base_path.path_join(result.get_string('file')), target_folder.path_join(result.get_string('file')))
			result = RegEx.create_from_string("\\Q\""+base_path+"\\E(?<file>[^\"]*)\"").search(scene_text)

	file = FileAccess.open(target_folder.path_join(target_file), FileAccess.WRITE)
	file.store_string(scene_text)
	file.close()

	find_parent('EditorView').plugin_reference.get_editor_interface().get_resource_filesystem().scan_sources()
	return target_folder.path_join(target_file)


func set_scene_path(path:String) -> void:
	var data: Dictionary = selected_item.get_metadata(0)
	data['scene'] = path
	update_preview.emit()
	changed.emit()
	reload_ui(data)


func reload_ui(data: Dictionary) -> void:
	var path: String = data.get('scene', '')
	%OpenSceneButton.hide()

	if path.is_empty():
		%SceneLabel.text = "Default Portrait Scene"
		%SceneLabel.tooltip_text = "Can be changed in the settings."
		%SceneLabel.add_theme_color_override("font_color", get_theme_color("readonly_color", "Editor"))

	elif %PortraitSceneBrowser.is_premade_portrait_scene(path):
		%SceneLabel.text = %PortraitSceneBrowser.portrait_scenes_info[path].name
		%SceneLabel.tooltip_text = path
		%SceneLabel.add_theme_color_override("font_color", get_theme_color("accent_color", "Editor"))

	else:
		%SceneLabel.text = path.get_file()
		%SceneLabel.tooltip_text = path
		%SceneLabel.add_theme_color_override("font_color", get_theme_color("property_color_x", "Editor"))
		%OpenSceneButton.show()

