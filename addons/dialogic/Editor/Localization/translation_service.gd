# Alternative to [TranslationServer] that works inside the editor
# This is a modified version of AnidemDex's TranslationService 
# https://github.com/AnidemDex/Godot-TranslationService

@tool
class_name DTS


# Translates a message using translation catalogs configured in the Editor Settings.
static func translate(message:String)->String:
	var translation
	
	translation = _get_translation(message)
	
	return translation


# Each value is an Array of [PHashTranslation].
static func get_translations() -> Dictionary:
	var translations_resources = ['en', 'zh_CN', 'es', 'fr', 'de']
	var translations = {}
	
	for resource in translations_resources:
		var t = load('res://addons/dialogic/Editor/Localization/dialogic.' + resource + '.translation')
		if translations.has(t.locale):
			translations[t.locale].append(t)
		else:
			translations[t.locale] = [t]
	return translations


static func _get_translation(message)->String:
	# TODO 
	return ''
