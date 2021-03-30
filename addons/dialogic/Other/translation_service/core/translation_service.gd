tool

# Alternative to [TranslationServer] that works inside the editor
# Modified to work with [Dialogic](https://github.com/coppolaemilio/dialogic)


# Translates a message using translation catalogs configured in the Project Settings.
static func translate(message:String)->String:
	var translation

	if Engine.editor_hint:
		translation = _get_translation(message)
		
	else:
		translation = TranslationServer.translate(message)
	
	return translation


# Returns a dictionary using translation catalogs configured in the Project Settings.
# Each key correspond to [locale](https://docs.godotengine.org/en/stable/tutorials/i18n/locales.html).
# Each value is an Array of [PHashTranslation].
static func get_translations() -> Dictionary:
	var translations_resources:PoolStringArray = ProjectSettings.get_setting("locale/translations")
	var translations = {}
	
	for resource in translations_resources:
		var t:PHashTranslation = load(resource)
		if translations.has(t.locale):
			translations[t.locale].append(t)
		else:
			translations[t.locale] = [t]
	return translations


static func _get_translation(_msg:String)->String:
	var _returned_translation:String = _msg
	var _translations:Dictionary = get_translations()
	var _default_fallback:String = ProjectSettings.get_setting("locale/fallback")
	var _test_locale:String = ProjectSettings.get_setting("locale/test")
	var _locale = TranslationServer.get_locale()
	
	if _test_locale:
		# There's a test locale property defined, use that instead editor locale
		_locale = _test_locale

	var cases = _translations.get(
		_locale, 
		_translations.get(_default_fallback, [PHashTranslation.new()])
		)
	for case in cases:
		_returned_translation = (case as PHashTranslation).get_message(_msg)
		if _returned_translation:
			break
		else:
			# If there's no translation, returns the original string
			_returned_translation = _msg
	return _returned_translation

	
# Unused, since i can't override Object methods
#static func tr(message:String)->String:
#    return translate(message)

