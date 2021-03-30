tool
class_name DialogicTranslator

const _TrService = preload("res://addons/dialogic/Other/translation_service/core/translation_service.gd")

# You can't override tr function
static func translate(message:String)->String:
	return _TrService.translate(message)
