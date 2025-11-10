@tool
class_name DialogicCharacterPrefixSuffixSection
extends DialogicCharacterEditorMainSection
## Character Editor Section for setting the prefix and suffix of a character.
##
## loads and sets the prefix and suffix of a character.
## Provides [const PREFIX_CUSTOM_KEY] and [const SUFFIX_CUSTOM_KEY] to
## access the `custom_info` dictionary of the [class DialogicCharacter].

@export var prefix_input: LineEdit
@export var suffix_input: LineEdit

## We won't force any prefixes or suffixes onto the player,
## to ensure their games are working as previously when updating.
const DEFAULT_PREFIX = ""
const DEFAULT_SUFFIX = ""

## `custom_info` dictionary keys for the prefix.
const PREFIX_CUSTOM_KEY = "prefix"

## `custom_info` dictionary keys for the prefix.
const SUFFIX_CUSTOM_KEY = "suffix"

var suffix := ""
var prefix := ""


func _ready() -> void:
	suffix_input.text_changed.connect(_suffix_changed)
	prefix_input.text_changed.connect(_prefix_changed)


func _suffix_changed(text: String) -> void:
	suffix = text


func _prefix_changed(text: String) -> void:
	prefix = text


func _get_title() -> String:
	return "Character Prefix & Suffix"


func _show_title() -> bool:
	return true


func _start_opened() -> bool:
	return false


func _load_portrait_data(portrait_data: Dictionary) -> void:
	_load_prefix_data(portrait_data)


## We load the prefix and suffix from the character's `custom_info` dictionary.
func _load_character(resource: DialogicCharacter) -> void:
	_load_prefix_data(resource.custom_info)


func _load_prefix_data(data: Dictionary) -> void:
	suffix = data.get(SUFFIX_CUSTOM_KEY, DEFAULT_SUFFIX)
	prefix = data.get(PREFIX_CUSTOM_KEY, DEFAULT_PREFIX)

	suffix_input.text = suffix
	prefix_input.text = prefix


## Whenever the user makes a save to the character, we save the prefix and suffix.
func _save_changes(character: DialogicCharacter) -> DialogicCharacter:
	if not character:
		printerr("[Dialogic] Unable to save Prefix and Suffix, the character is missing.")
		return character

	character.custom_info[PREFIX_CUSTOM_KEY] = prefix
	character.custom_info[SUFFIX_CUSTOM_KEY] = suffix

	return character
