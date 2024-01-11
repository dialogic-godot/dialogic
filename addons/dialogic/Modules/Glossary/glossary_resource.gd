@tool
## Resource used to store glossary entries. Can be saved to disc and used as a glossary.
## Add/create glossaries fom the glossaries editor
class_name DialogicGlossary
extends Resource

## Stores all entries for the glossary.
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
## Property in a glossary entry.
const TITLE_PROPERTY := "title"
## Property in a glossary entry.
const TEXT_PROPERTY := "text"
## Property in a glossary entry.
const EXTRA_PROPERTY := "extra"
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
## entry key such as "name" or "alternatives".
## The values correspond to the matching index in [member entries].
##
## We cannot use use a dictionary with multiple keys for the [member entries]
## leading to the same in-memory dictionaries, because when this resource
## is saved to disk, the dictionary references will turn into duplicates.
@export var _entry_keys: Dictionary = {}

func __get_property_list() -> Array:
	return []


## Erases an entry key based the given [param entry_key].
func remove_entry_key(entry_key: String) -> void:
	_entry_keys.erase(entry_key)


## Updates the glossary entry's name and the [member _entry_keys] lookup table.
## The [param old_entry_key] is the old unique name of the entry.
## The [param new_entry_key] is the new unique name of the entry.
##
## This method fails if the [param old_entry_key] does not exist.
func replace_entry_key(old_entry_key: String, new_entry_key: String) -> void:
	var entry_index: int = _find_entry_index_by_key(old_entry_key)

	if entry_index == _MISSING_ENTRY_INDEX:
		return

	var entry := entries[entry_index]

	entry[NAME_PROPERTY] = new_entry_key

	_entry_keys.erase(old_entry_key)
	_entry_keys[new_entry_key] = entry_index


## If the entry key does not exist, the entry may still exist.
## This happens when a manipulation of the glossary fails at some point or
## the file is corrupted.
##
## Runtime complexity:
## In case where the entry key couldn't be found, the runtime complexity is
## O(n), where n is the number of entries in this glossary.
func _find_entry_index_by_key(entry_key: String) -> int:
	var entry_index: int = _entry_keys.get(entry_key, _MISSING_ENTRY_INDEX)
	var is_valid := entry_index < entries.size()

	if entry_index == _MISSING_ENTRY_INDEX or not is_valid:

		for i in entries.size():
			var entry: Dictionary = entries[i]

			if (entry[NAME_PROPERTY] == entry_key
			or entry_key in entry.get(ALTERNATIVE_PROPERTY, [])):
				return i

		return _MISSING_ENTRY_INDEX

	return entry_index


## Erases an entry from this glossary.
##
## Returns -1 if the entry does not exist.
func erase_entry(entry_key: String) -> int:
	var entry_index: int = _find_entry_index_by_key(entry_key)

	if _MISSING_ENTRY_INDEX:
		return _MISSING_ENTRY_INDEX

	_remove_entry_at(entry_index)
	_entry_keys.erase(entry_key)

	return entry_index


## Removes an entry at the given [param entry_index].
## Does not remove the matching entry key from the [member _entry_keys]
## lookup table.
func _remove_entry_at(entry_index: int) -> void:
	entries.remove_at(entry_index)

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


## The [param entry_key] must be valid entry key for an entry.
## Adds the [param alias] as a valid entry key for that entry.
##
## Returns the index of the entry, -1 if the entry does not exist.
func add_entry_key_alias(entry_key: String, alias: String) -> bool:
	var index: int = _entry_keys.get(entry_key, _MISSING_ENTRY_INDEX)

	if index == _MISSING_ENTRY_INDEX:
		return _MISSING_ENTRY_INDEX

	_entry_keys[alias] = index
	return index


## Adds a new entry to this glossary.
## Adds the name and alternatives as entry keys.
##
## This is a private method, it's recommended to use [method set_entry],
## which uses this method internally, if the entry key does not exist yet.
func _add_entry(entry: Dictionary) -> void:
	var entry_key: String = entry[NAME_PROPERTY]
	entries.append(entry)
	var highest_new_index := entries.size() - 1

	for alternative: String in entry.get(DialogicGlossary.ALTERNATIVE_PROPERTY, []):
		_entry_keys[alternative] = highest_new_index

	_entry_keys[entry_key] = highest_new_index

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


## Returns an array of words that can trigger the glossary popup.
## This method respects whether translation is enabled or not.
## The words may be: The entry key and the alternative words.
func _get_word_options(entry_key: String) -> Array:
	var word_options: Array = []

	var translation_enabled: bool = ProjectSettings.get_setting("dialogic/translation/enabled", false)

	if not translation_enabled:
		word_options.append(entry_key)

		for alternative: String in get_entry(entry_key).get(ALTERNATIVE_PROPERTY, []):
			word_options.append(alternative)

		return word_options

	var translation_entry_key_id: String = get_property_translation_key(entry_key, NAME_PROPERTY)

	if translation_entry_key_id.is_empty():
		return []

	print("[GLOSSARY] Translation entry key ID: " + translation_entry_key_id)
	var translated_entry_key := tr(translation_entry_key_id)

	if not translated_entry_key == translation_entry_key_id:
		word_options.append(translated_entry_key)

	var translation_alternatives_id: String = get_property_translation_key(entry_key, ALTERNATIVE_PROPERTY)
	var translated_alternatives_str := tr(translation_alternatives_id)

	if not translated_alternatives_str == translation_alternatives_id:
		var translated_alternatives := translated_alternatives_str.split(",")

		for alternative: String in translated_alternatives:
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
	print("[GLOSSARY] Word options for: " + entry_key + " are: " + str(word_options))
	regex_option = "|".join(word_options)

	regex_options[locale_key] = regex_option

	return regex_option


## This is automatically called, no need to use this.
func add_translation_id() -> String:
	_translation_id = DialogicUtil.get_next_translation_id()
	return _translation_id


## Removes the translation ID of this glossary.
func remove_translation_id() -> void:
	_translation_id = ""


## Removes the translation ID of all glossary entries.
func remove_entry_translation_ids() -> void:
	for entry: Dictionary in entries:

		if entry.has(TRANSLATION_PROPERTY):
			entry.erase(TRANSLATION_PROPERTY)


## Clears the lookup tables using translation keys.
func clear_translation_keys() -> void:
	const RESOURCE_NAME_KEY := RESOURCE_NAME + "/"

	for translation_key: String in _entry_keys.keys():

		if translation_key.begins_with(RESOURCE_NAME_KEY):
			_entry_keys.erase(translation_key)

	_translation_keys.clear()


## Returns a key used to reference this glossary in the translation CSV file.
##
## Time complexity: O(1)
func get_property_translation_key(entry_key: String, property: String) -> String:
	print("[GLOSSARY] Getting translation key for: " + entry_key + " and property: " + property)
	var entry_index: int = _find_entry_index_by_key(entry_key)

	if entry_index == _MISSING_ENTRY_INDEX:
		return ""

	var entry := entries[entry_index]
	var entry_translation_key: String = entry.get(TRANSLATION_PROPERTY, "")

	if entry_translation_key.is_empty() or _translation_id.is_empty():
		return ""

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

	var glossary_translation_id: String = glossary_entry.get(TRANSLATION_PROPERTY, "")

	if glossary_translation_id.is_empty():
		entry_translation_id = DialogicUtil.get_next_translation_id()
		glossary_entry[TRANSLATION_PROPERTY] = entry_translation_id

	else:
		entry_translation_id = glossary_entry[TRANSLATION_PROPERTY]

	return entry_translation_id


## Tries to get the glossary's translation ID.
## If it does not exist, a new one will be generated.
func get_set_glossary_translation_id() -> String:
	if _translation_id == null or _translation_id.is_empty():
		add_translation_id()

	return _translation_id

