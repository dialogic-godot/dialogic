@tool
class_name DialogicGlossary
extends Resource

## Resource used to store glossary entries. Can be saved to disc and used as a glossary.
## Add/create glossaries fom the glossaries editor

## Stores all entry information
@export var entries: Dictionary = {}

## If false, no entries from this glossary will be shown
@export var enabled: bool = true


const GLOSSARY_NAME = "Glossary"

## Private ID assigned when this glossary is translated.
var _translation_id: String = ""

func __get_property_list() -> Array:
	return []


## This is automatically called, no need to use this.
func add_translation_id() -> String:
	_translation_id = DialogicUtil.get_next_translation_id()
	return _translation_id


func remove_translation_id() -> void:
	_translation_id = ""

## Returns a key used in the firs
func get_property_translation_key(property: String) -> String:
	var glossary_csv_key := GLOSSARY_NAME.path_join(_translation_id).path_join(property)

	return glossary_csv_key
