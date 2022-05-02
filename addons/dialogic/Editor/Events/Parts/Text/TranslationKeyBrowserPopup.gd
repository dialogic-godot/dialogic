tool
extends PopupPanel


signal key_selected


func show_keys():
	_clear_buttons()
	
	var translation_location = DialogicResources.get_settings_value("Dialog", "TranslationLocation", "")
	var translation_files = _get_translation_files(translation_location)
	for file in translation_files:
		var new_button = Button.new()
		$HBoxContainer/ScrollContainer/Content.add_child(new_button)
		new_button.text = file.split(".")[0]
		new_button.text = new_button.text.split("/")[-1]
		new_button.hint_tooltip = new_button.text
		new_button.clip_text = true
		new_button.connect("pressed", self, "_on_file_button_pressed", [file])
	
	popup_centered_minsize(Vector2(475, 300))


func _clear_buttons():
	$HBoxContainer/ScrollContainer/Content/BackButton.visible = false
	
	for i in range($HBoxContainer/ScrollContainer/Content.get_child_count() - 1, 0, -1):
		$HBoxContainer/ScrollContainer/Content.get_child(i).queue_free()


func _on_file_button_pressed(var file_path):
	_clear_buttons()
	$HBoxContainer/ScrollContainer/Content/BackButton.visible = true
	
	var file = File.new()
	var keys = []
	var content = []
	
	if not file.open(file_path, 1) == OK:
		printerr("[Dialogic] Error opening file at " + file_path + "!")
		show_keys()
		return
		
	var line = file.get_csv_line(",") # get rid of the first line
	var locale_index = _get_locale_index(line)
	
	while file.get_position() < file.get_len():
		line = file.get_csv_line(",")
		keys.append(line[0])
		content.append(line[locale_index])
	
	#print(keys)
	
	for i in range(keys.size()):
		var new_button = Button.new()
		$HBoxContainer/ScrollContainer/Content.add_child(new_button)
		new_button.clip_text = true
		new_button.text = keys[i]
		new_button.connect("pressed", self, "_on_key_selected", [keys[i]])
		new_button.connect("mouse_entered", self, "_on_key_hovered", [content[i]])


func _on_key_selected(var key : String):
	emit_signal("key_selected", key)


func _on_key_hovered(var content : String):
	$HBoxContainer/KeyContents.text = content


func _get_locale_index(var csv_line : PoolStringArray) -> int:
	var editor_plugin = EditorPlugin.new()
	var editor_settings = editor_plugin.get_editor_interface().get_editor_settings()
	var locale = editor_settings.get('interface/editor/editor_language')
	
	for i in range(csv_line.size()):
		if csv_line[i] == locale:
			return i
	return -1


func _get_translation_files(var base_folder) -> Array:
	var result = []
	
	var dir = Directory.new()
	var err = dir.open(base_folder)
	if not err == OK:
		printerr("[Dialogic] Error loading translations at " + base_folder + "!")
		return result
	
	dir.list_dir_begin(true)
	var file_name : String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			result.append_array(_get_translation_files(base_folder + "/" + file_name))
			file_name = dir.get_next()
			continue
		if file_name.ends_with(".csv"):
			result.append(base_folder + "/" + file_name)
		file_name = dir.get_next()
	
	return result




func _on_BackButton_pressed() -> void:
	show_keys()
