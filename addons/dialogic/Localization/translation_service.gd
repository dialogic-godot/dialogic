# Alternative to [TranslationServer] that works inside the editor
# This is a modified version of AnidemDex's TranslationService 
# https://github.com/AnidemDex/Godot-TranslationService

tool
class_name DTS

var translations = {}
#var testText = "Initial Text"

func _init():
	translations_initial_load()

# Translates a message using translation catalogs configured in the Editor Settings.
func translate(message:String)->String:
	var translation
	
	translation = _get_translation(message)
	
	return translation

func translations_initial_load():		
	var translations_resources = ['en', 'zh_CN', 'es', 'fr', 'de']
	translations = {}
	
	for resource in translations_resources:
		var t:PHashTranslation = load('res://addons/dialogic/Localization/dialogic.' + resource + '.translation')
		if translations.has(t.locale):
			translations[t.locale].append(t)
		else:
			translations[t.locale] = [t]


# Each value is an Array of [PHashTranslation].
func get_translations() -> Dictionary:
	return translations


func _get_translation(message)->String:
	var returned_translation = message
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
