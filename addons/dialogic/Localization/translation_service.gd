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
	editor_plugin.queue_free()
	return returned_translation


static func _get_translation_location(var key : String) -> String:
	var translation_files = _get_translation_files('res://addons/dialogic/Localization')
	translation_files.append_array(_get_translation_files(DialogicResources.get_settings_value("Dialog", "TranslationLocation", "")))
	
	for file in translation_files:
		var t : PHashTranslation = load(file)
		if(t.get_message(key) != ""):
			return file
	
	return ""
