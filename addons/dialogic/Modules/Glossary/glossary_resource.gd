@tool
class_name DialogicGlossary
extends Resource

## Resource used to store glossary entries. Can be saved to disc and used as a glossary.
## Add/create glossaries fom the glossaries editor

## Stores all entry information
@export var entries: Array[Dictionary] = []

## If false, no entries from this glossary will be shown
@export var enabled: bool = true

## Refers to the translation type of this resource used for CSV translation files.
const RESOURCE_NAME := "Glossary"
## The name of glossary entries, the value is the key in [member entries].
## This constant is used for CSV translation files.
const NAME_PROPERTY := "name"
## Property in a glossary entry. Alternative words for the entry name.
const ALTERNATIVE_PROPERTY := "alternatives"
## Property in a glossary entry. The translation ID of the entry.
## May be empty if the entry has not been translated yet.
const TRANSLATION_PROPERTY := "_translation_id"
## Property in a glossary entry.
const REGEX_OPTION_PROPERTY := "regex_options"
## Prefix used for private properties in entries.
## Ignored when entries are translated.
const PRIVATE_PROPERTY_PREFIX := "_"

const _MISSING_ENTRY_INDEX := -1

## Private ID assigned when this glossary is translated.
@export var _translation_id: String = ""

## Private lookup table used to find the translation ID of a glossary entry.
## The keys (String) are all translated words that may trigger a glossary entry to
## be shown.
## The values (String) are the translation ID.
@export var _translation_keys: Dictionary = {}

## Private lookup table used to find the correct entry index for a glossary
## entry name such as "name" or "alternatives".
##
@export var _entry_keys: Dictionary = {}

func __get_property_list() -> Array:
	return []


func remove_entry_key(entry_key: String) -> void:
	_entry_keys.erase(entry_key)


## Updates the glossary entry's name and the [member _entry_keys] lookup table.
## The [param old_entry_key] is the old unique name of the entry.
## The [param new_entry_key] is the new unique name of the entry.
##
## This method fails if the [param old_entry_key] does not exist.
func replace_entry_key(old_entry_key: String, new_entry_key: String) -> void:
	var old_key: int = _entry_keys.get(old_entry_key, _MISSING_ENTRY_INDEX)

	if old_key == _MISSING_ENTRY_INDEX:
		return

	_entry_keys.erase(old_entry_key)
	_entry_keys[new_entry_key] = old_key
	print("[GLOSSARY] Replaced entry key: " + old_entry_key + " with: " + new_entry_key)


func erase_entry(entry_key: String) -> void:
	var entry_index: int = _entry_keys.get(entry_key, _MISSING_ENTRY_INDEX)

	if entry_index == _MISSING_ENTRY_INDEX:
		print("[GLOSSARY] Could not find entry key: " + entry_key)
		return

	entries.remove_at(entry_index)
	_entry_keys.erase(entry_key)

	for key: String in _entry_keys.keys():
		var index: int = _entry_keys[key]

		if index == entry_index:
			_entry_keys.erase(key)

		elif index > entry_index:
			_entry_keys[key] = index - 1


## The [param entry_key] must be valid name of an entry.
## Valid names are the unique entry "name" or any of the comma-delimited
## "alternatives".
##
## If the [param entry_key] is not valid, an empty dictionary will be returned.
## A valid dictionary is never empty.
##
## The returned dictionary is a reference and can be mutated.
## Be aware, the glossary resource must be saved to disc for the changes to
## to persist.
func get_entry(entry_name: String) -> Dictionary:
	var entry_key: int = _entry_keys.get(entry_name, _MISSING_ENTRY_INDEX)

	if entries.size() > entry_key:
		return entries[entry_key]

	return {}


func add_entry_key_alias(old_entry_key: String, new_entry_key: String) -> void:
	var index: int = _entry_keys.get(old_entry_key, _MISSING_ENTRY_INDEX)

	if index == _MISSING_ENTRY_INDEX:
		return

	_entry_keys[new_entry_key] = index


func _add_entry(entry: Dictionary) -> void:
	var entry_key: String = entry[NAME_PROPERTY]
	entries.append(entry)
	_entry_keys[entry_key] = entries.size()


## Adds a glossary entry.
## Sets [param entry_key] as valid entry key and [param entry] as
## glossary entry.
##
## If there are previous values for either of these parameters, they will
## be overwritten.
##
## To update an entry, use [method get_entry] and mutate the returned
## dictionary.
func set_entry(entry_key: String, entry: Dictionary) -> void:
	var entry_index: int = _entry_keys.get(entry_key, _MISSING_ENTRY_INDEX)

	if entry_index == _MISSING_ENTRY_INDEX:
		_add_entry(entry)

	else:
		entries[entry_index] = entry


## Returns an array of translated words that can trigger the glossary popup.
## These words may be: The entry key and the alternative words.
func _get_word_options(entry_key: String) -> Array:
	var word_options: Array = []

	var translation_entry_key_id: String = get_property_translation_key(entry_key, NAME_PROPERTY)
	var translated_entry_key := tr(translation_entry_key_id)

	if not translated_entry_key == translation_entry_key_id:
		word_options.append(translated_entry_key)

	var translation_alternatives_id: String = get_property_translation_key(entry_key, ALTERNATIVE_PROPERTY)
	var translated_alternatives_str := tr(translation_alternatives_id)

	if not translated_alternatives_str == translation_alternatives_id:
		var translated_alternatives := translated_alternatives_str.split(",")

		for alternative: String in translated_alternatives:
			print(alternative)
			word_options.append(alternative)

	return word_options


## Gets the regex option for the given [param entry_key].
## If the regex option does not exist, it will be generated.
##
## A regex option is the accumulation of valid words that can trigger the
## glossary popup.
##
## The [param entry_key] must be valid or an error will occur.
func get_set_regex_option(entry_key: String) -> String:
	var entry: Dictionary = get_entry(entry_key)

	var regex_options: Dictionary = entry.get(REGEX_OPTION_PROPERTY, {})

	if regex_options.is_empty():
		entry[REGEX_OPTION_PROPERTY] = regex_options

	var locale_key: String = TranslationServer.get_locale()
	var regex_option: String = regex_options.get(locale_key, "")

	if not regex_option.is_empty():
		return regex_option

	var word_options: Array = _get_word_options(entry_key)
	regex_option = "|".join(word_options)

	regex_options[locale_key] = regex_option

	return regex_option


## This is automatically called, no need to use this.
func add_translation_id() -> String:
	_translation_id = DialogicUtil.get_next_translation_id()
	return _translation_id


func remove_translation_id() -> void:
	_translation_id = ""


## Returns a key used to reference this glossary in the translation CSV file.
##
## Time complexity: O(1)
func get_property_translation_key(entry_key: String, property: String) -> String:
	var entry: Dictionary = get_entry(entry_key)
	var entry_translation_key: String = entry.get(TRANSLATION_PROPERTY, "")

	var glossary_csv_key := (RESOURCE_NAME
		.path_join(_translation_id)
		.path_join(entry_translation_key)
		.path_join(property))

	return glossary_csv_key


## Returns the matching translation key for the given [param word].
## This key can be used via [method tr] to get the translation.
##
## Time complexity: O(1)
## Uses an internal dictionary to find the translation key.
## This dictionary is generated when the glossary is translated.
## See [member _translation_keys].
func get_word_translation_key(word: String) -> String:
	if _translation_keys.has(word):
		return _translation_keys[word]

	return ""


## Returns the translation key prefix for this glossary.
## The resulting format will look like this: Glossary/a2/
## This prefix can be used to find translations for this glossary.
func _get_glossary_translation_id_prefix() -> String:
	return (
		DialogicGlossary.RESOURCE_NAME
			.path_join(_translation_id)
	)


## Returns the translation key for the given [param glossary_translation_id] and
## [param entry_translation_id].
##
## By key, we refer to the uniquely named property per translation entry.
##
## The resulting format will look like this: Glossary/a2/b4/name
func _get_glossary_translation_key(entry_translation_id: String, property: String) -> String:
	return (
		DialogicGlossary.RESOURCE_NAME
			.path_join(_translation_id)
			.path_join(entry_translation_id)
			.path_join(property)
	)


## Tries to get the glossary entry's translation ID.
## If it does not exist, a new one will be generated.
func get_set_glossary_entry_translation_id(entry_key: String) -> String:
	var glossary_entry: Dictionary = get_entry(entry_key)
	var entry_translation_id := ""

	if glossary_entry.has(TRANSLATION_PROPERTY):
		entry_translation_id = glossary_entry[TRANSLATION_PROPERTY]

	else:
		entry_translation_id = DialogicUtil.get_next_translation_id()
		glossary_entry[TRANSLATION_PROPERTY] = entry_translation_id

	return entry_translation_id


## Tries to get the glossary's translation ID.
## If it does not exist, a new one will be generated.
func get_set_glossary_translation_id() -> String:

	if _translation_id == null or _translation_id.is_empty():
		_translation_id = DialogicUtil.get_next_translation_id()

	return _translation_id

