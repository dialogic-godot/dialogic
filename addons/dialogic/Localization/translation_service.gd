# Alternative to [TranslationServer] that works inside the editor
# This is a modified version of AnidemDex's TranslationService 
# https://github.com/AnidemDex/Godot-TranslationService

tool
class_name DTS


# Translates a message using translation catalogs configured in the Editor Settings.
static func translate(message:String)->String:
	var translation
	
	translation = _get_translation(message)
	
	return translation


# Each value is an Array of [PHashTranslation].
static func get_translations() -> Dictionary:
	var translations = {}
	
	var translation_files = _get_translation_files('res://addons/dialogic/Localization')
	translation_files.append_array(_get_translation_files(DialogicResources.get_settings_value("Dialog", "TranslationLocation", "")))
	
	for file in translation_files:
		var t : PHashTranslation = load(file)
		if translations.has(t.locale):
			translations[t.locale].append(t)
		else:
			translations[t.locale] = [t]
	
	return translations


static func _get_translation_files(var base_folder) -> Array:
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
		if file_name.ends_with(".translation"):
			result.append(base_folder + "/" + file_name)
		file_name = dir.get_next()
	
	return result


static func _get_translation(message)->String:
	var returned_translation = message
	var translations = get_translations()
	var default_fallback = 'en'
	
	var editor_plugin = EditorPlugin.new()
	var editor_settings = editor_plugin.get_editor_interface().get_editor_settings()
	var locale = editor_settings.get('interface/editor/editor_language')
	
	var cases = translations.get(
		locale, 
		translations.get(default_fallback, [PHashTranslation.new()])
		)
	for case in cases:
		returned_translation = (case as PHashTranslation).get_message(message)
		if returned_translation:
			break
		else:
			# If there's no translation, returns the original string
			returned_translation = message
	
	#print('Message: ', message, ' - locale: ', locale, ' - ', returned_translation)
	return returned_translation


static func _get_translation_location(var key : String) -> String:
	var translation_files = _get_translation_files('res://addons/dialogic/Localization')
	translation_files.append_array(_get_translation_files(DialogicResources.get_settings_value("Dialog", "TranslationLocation", "")))
	
	for file in translation_files:
		var t : PHashTranslation = load(file)
		if(t.get_message(key) != ""):
			return file
	
	return ""


static func save_translation(var key : String, var value : String) -> void:
	var file_path = _get_translation_location(key)
	
	# Since we need to edit the CSV and not the .translation file, we replace the extension
	var csv_path = file_path.split(".")[0] + ".csv"

	_replace_csv_line(csv_path, key, value)

static func save_translation_at(var key : String, var value : String, var path : String) -> void:
	_replace_csv_line(path, key, value)


# Replace a value in a line of a csv or append to it if it doesn't exist.
static func _replace_csv_line(var path, var key, var value):
	var file : File = File.new()
	var err = file.open(path, 3)
	if err != OK:
		printerr("[Dialogic] Error opening file to save: " + path + "(" + String(err) + ")")
		return
	
	var result_string : String = ""
	var found = false
	
	var locales = file.get_csv_line(",")
	var locale_index = _get_locale_index(locales)
	if locale_index == -1:
		file.close()
		return
	
	result_string += locales.join(",") + "\n"
	
	var line 
	while file.get_position() < file.get_len():
		line = file.get_csv_line(",")
		
		var key_in_line = line[0] # The key is always the first thing
		if key_in_line == key and not found: # Some edge cases will have us find the same line twice
			found = true
			line[locale_index] = value
			line = _add_quotes_to_csv_line(line)
			result_string += line.join(",") + "\n"
			continue
		
		line = _add_quotes_to_csv_line(line)
		result_string += line.join(",") + "\n"
	
	if not found:
		var new_line = PoolStringArray([key])
		new_line.resize(locales.size() + 1)
		new_line[locale_index] = value
		new_line = _add_quotes_to_csv_line(new_line)
		file.store_csv_line(new_line, ",")
		result_string += new_line.join(",") + "\n"
	
	file.close()
	
	file.open(path, 2)
	file.store_string(result_string)
	file.close()
	
	# We need to delete the .lang.translation to get Godot to regenerate it
	var file_to_delete_path = path.split(".")[0] + "." + locales[locale_index] + ".translation"
	var dir = Directory.new()
	dir.remove(file_to_delete_path)
	
	# Jank, but not sure how to do it otherwise.
	EditorPlugin.new().get_editor_interface().get_resource_filesystem().scan()



static func _add_quotes_to_csv_line(var csv_line : PoolStringArray) -> PoolStringArray:
	for i in range(1, csv_line.size(), 1):
		csv_line[i] = "\"" + csv_line[i] + "\""
	return csv_line


static func _get_locale_index(var csv_line : PoolStringArray) -> int:
	var editor_plugin = EditorPlugin.new()
	var editor_settings = editor_plugin.get_editor_interface().get_editor_settings()
	var locale = editor_settings.get('interface/editor/editor_language')
	
	for i in range(csv_line.size()):
		if csv_line[i] == locale:
			return i
	return -1
