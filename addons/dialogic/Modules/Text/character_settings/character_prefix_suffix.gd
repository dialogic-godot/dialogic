@tool
class_name DialogicCharacterEditorMainSection
extends Control

## Base class for all character editor main sections. Methods should be overridden.

## Reference to the character editor, set when instantiated
var character_editor: Control

## If not empty, a hint icon is added to the section title.
var hint_text := ""

@export var prefix_input: LineEdit
@export var suffix_input: LineEdit

## We won't force any prefixes or suffixes onto the player,
## to ensure their games are working as previously when updating.
const DEFAULT_PREFIX = ""
const DEFAULT_SUFFIX = ""

const PREFIX_CUSTOM_KEY = "prefix"
const SUFFIX_CUSTOM_KEY = "suffix"

## Overwrite to set the title of this section
func _get_title() -> String:
	return "Character Prefix & Suffix"


## Overwrite to set the visibility of the section title
func _show_title() -> bool:
	return true


## Overwrite to set whether this should initially be opened.
func _start_opened() -> bool:
	return false


## Overwrite to load all the information from the character into this section.
func _load_character(_resource: DialogicCharacter) -> void:
	prefix_input.text = _resource.custom_info.get(PREFIX_CUSTOM_KEY, DEFAULT_PREFIX)
	suffix_input.text = _resource.custom_info.get(SUFFIX_CUSTOM_KEY, DEFAULT_SUFFIX)


## Overwrite to save all changes made in this section to the resource.
## In custom sections you will mostly likely save to the [resource.custom_info]
##  dictionary.
func _save_changes(character: DialogicCharacter) -> DialogicCharacter:
	character.custom_info[PREFIX_CUSTOM_KEY] = prefix_input.text
	character.custom_info[SUFFIX_CUSTOM_KEY] = suffix_input.text

	return character
