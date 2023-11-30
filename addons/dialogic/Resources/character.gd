@tool
extends Resource
class_name DialogicCharacter


@export var display_name:String = ""
@export var nicknames:Array = []

@export var color:Color = Color()
@export var description:String = ""

@export var scale:float = 1.0
@export var offset:Vector2 = Vector2()
@export var mirror:bool = false

@export var default_portrait:String = ""
@export var portraits:Dictionary = {}

@export var custom_info:Dictionary = {}

## All valid properties that can be accessed by their translation.
enum TranslatedProperties {
	NAME,
	NICKNAMES,
}

var _translation_id: String = ""

func __get_property_list() -> Array:
	return []


func _to_string() -> String:
	return "[{name}:{id}]".format({"name":get_character_name(), "id":get_instance_id()})

func _hide_script_from_inspector() -> bool:
	return true

## This is automatically called, no need to use this.
func add_translation_id() -> String:
	_translation_id = DialogicUtil.get_next_translation_id()
	return _translation_id


func remove_translation_id() -> void:
	_translation_id = ""

## Checks [param property] and matches it to a translation key.
##
## Undefined behaviour if an invalid integer is passed.
func get_property_translation_key(property: TranslatedProperties) -> String:
	var property_key := ""

	match property:
		TranslatedProperties.NAME:
			property_key = "name"
		TranslatedProperties.NICKNAMES:
			property_key = "nicknames"

	return "Character".path_join(_translation_id).path_join(property_key)


## Accesses the original text of the character.
##
## Undefined behaviour if an invalid integer is passed.
func _get_property_original_text(property: TranslatedProperties) -> String:
	match property:
		TranslatedProperties.NAME:
			return display_name
		TranslatedProperties.NICKNAMES:
			return ", ".join(nicknames)

	return ""


## Access a property of the character and if conditions are met, attempts to
## translate the property.
##
## The translation feature must be enabled in the project settings.
## The translation ID must be set.
## Otherwise, returns the text property as is.
##
## Undefined behaviour if an invalid integer is passed.
func _get_property_translated(property: TranslatedProperties) -> String:
	var try_translation: bool = (_translation_id != null
		and not _translation_id.is_empty()
		and ProjectSettings.get_setting('dialogic/translation/enabled', false)
	)

	if try_translation:
		var translation_key := get_property_translation_key(property)
		var translated_property := tr(translation_key)

		# If no translation is found, tr() returns the ID.
		# However, we want to fallback to the original text.
		if translated_property == translation_key:
			return _get_property_original_text(property)

		return translated_property

	else:
		return _get_property_original_text(property)


## Translates the nicknames of the characters and then returns them as an array
## of strings.
func get_nicknames_translated() -> Array:
	var translated_nicknames := _get_property_translated(TranslatedProperties.NICKNAMES)
	return (translated_nicknames.split(", ") as Array)


## Translates and returns the display name of the character.
func get_display_name_translated() -> String:
	return _get_property_translated(TranslatedProperties.NAME)


## Returns the name of the file (without the extension).
func get_character_name() -> String:
	if !resource_path.is_empty():
		return resource_path.get_file().trim_suffix('.dch')
	elif !display_name.is_empty():
		return display_name.validate_node_name()
	else:
		return "UnnamedCharacter"

## Returns the info of the given portrait.
## Uses the default portrait if the given portrait doesn't exist.
func get_portrait_info(portrait_name:String) -> Dictionary:
	return portraits.get(portrait_name, portraits.get(default_portrait, {}))
