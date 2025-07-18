@tool
@icon("uid://bbea0efx0ybu7")
extends "res://addons/dialogic/Resources/dialogic_identifiable_resource.gd"
class_name DialogicCharacter


## Resource that represents a character in dialog.
## Manages/contains portraits, custom info and translation of characters.

@export var display_name := ""
@export var nicknames := []

@export var color := Color()
@export var description := ""

@export var scale  := 1.0
@export var offset := Vector2()
@export var mirror := false

@export var default_portrait := ""
@export var portraits := {}

@export var custom_info := {}

## All valid properties that can be accessed by their translation.
enum TranslatedProperties {
	NAME,
	NICKNAMES,
}

var _translation_id := ""


func _get_extension() -> String:
	return "dch"


func _get_resource_name() -> String:
	return "DialogicCharacter"


## Adds a translation ID to the character.
func add_translation_id() -> String:
	_translation_id = DialogicUtil.get_next_translation_id()
	return _translation_id


## Returns the character's translation ID.
## Adds a translation ID to the character if it doesn't have one.
func get_set_translation_id() -> String:
	if _translation_id == null or _translation_id.is_empty():
		return add_translation_id()
	else:
		return _translation_id


## Removes the translation ID from the character.
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


## Returns the best name for this character.
func get_character_name() -> String:
	var unique_identifier := get_identifier()
	if not unique_identifier.is_empty():
		return unique_identifier
	if not resource_path.is_empty():
		return resource_path.get_file().trim_suffix('.dch')
	elif not display_name.is_empty():
		return display_name.validate_node_name()
	else:
		return "UnnamedCharacter"


## Returns the info of the given portrait.
## Uses the default portrait if the given portrait doesn't exist.
func get_portrait_info(portrait_name:String) -> Dictionary:
	return portraits.get(portrait_name, portraits.get(default_portrait, {}))


## Helper method intended for a simplified creation of portraits at runtime.
## For more complex needs, manually writing to the portraits dict is recommended.
func add_portrait(name:String, image:String, scene:= "") -> void:
	portraits[name] = {
		"scene": scene,
		"export_overrides": {
			"image": image}
		}
