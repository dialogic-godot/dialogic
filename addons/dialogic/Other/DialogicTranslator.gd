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

static func translate_node_recursively(node:Node):
	_get_nodes_recursively(node)
	pass


static func _get_nodes_recursively(main_node:Node):
	for node in main_node.get_children():
		if node.get_child_count() > 0:
			_translate_node(node)
			_get_nodes_recursively(node)
		else:
			_translate_node(node)
	_translate_node(main_node)


static func _translate_node(node:Node):
	match node.get_class():
		"Button", "ToolButton", "Label", "Control":
			if node.has_meta("TEXT_KEY"):
				node.text = translate(node.get_meta("TEXT_KEY"))

			if node.has_meta("HINT_TOOLTIP_KEY"):
				(node as Control).hint_tooltip = translate(node.get_meta("HINT_TOOLTIP_KEY"))
	
			continue
		"PopupMenu":
			for _item_idx in range((node as PopupMenu).get_item_count()):
				var _item_metadata = (node as PopupMenu).get_item_metadata(_item_idx)
				if typeof(_item_metadata) == TYPE_STRING:
					(node as PopupMenu).set_item_text(_item_idx, translate(_item_metadata))
		"ConfirmationDialog":
			if node.has_meta("DIALOG_TEXT_KEY"):
				(node as ConfirmationDialog).dialog_text = translate(node.get_meta("DIALOG_TEXT_KEY"))
		_:
			pass
		
	pass
