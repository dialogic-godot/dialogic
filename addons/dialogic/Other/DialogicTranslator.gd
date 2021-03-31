tool
class_name DialogicTranslator

const _TrService = preload("res://addons/dialogic/Other/translation_service/core/translation_service.gd")

const DIALOGIC_TRANSLATIONS:PoolStringArray = preload("res://addons/dialogic/Translations/dialogic_translations_resource.tres").translations

# You can't override tr function
static func translate(message:String)->String:
	return _TrService.translate(message)


## Load the translations saved in DIALOGIC_TRANSLATIONS
## This must be called once, but it can be called again if
## you want to make some kind of "dynamic translation loads"
static func load_translations()->void:
	var project_translations:Array = Array(ProjectSettings.get_setting("locale/translations")) 
	var dialogic_translations:Array = Array(DIALOGIC_TRANSLATIONS)
	
	for translation in dialogic_translations:
		
		if project_translations.has(translation):
			continue
		
		project_translations.append(translation)
	
	var new_pr_translations = PoolStringArray(project_translations)
	ProjectSettings.set_setting("locale/translations", new_pr_translations)
	var err = ProjectSettings.save()
	if err != OK:
		print("{error} There was an error while adding the translations: {error_info}".format(
			{"error":DialogicUtil.Error.DIALOGIC_ERROR,
			"error_info":err}))
	else:
		print("[Dialogic] All translations added") # Replace with translation
