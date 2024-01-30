@tool
## Resource used to store glossary entries. Can be saved to disc and used as a glossary.
## Add/create glossaries fom the glossaries editor
class_name DialogicGlossary
extends Resource

## Stores all entries for the glossary.
##
## The value may either be a dictionary, representing an entry, or
## a string, representing the actual key for the key used.
## The string key-value pairs are the alias keys, they allow to redirect
## the actual glossary entry.
@export var entries: Dictionary = {}

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


func __get_property_list() -> Array:
	return []


## Removes an entry and all its aliases (alternative property) from
## the glossary.
## [param entry_key] may be an entry name or an alias.
##
## Returns true if the entry matching the given [param entry_key] was found.
func remove_entry(entry_key: String) -> bool:
	var entry: Dictionary = get_entry(entry_key)

	if entry.is_empty():
		return false

	var aliases: Array = entry.get(ALTERNATIVE_PROPERTY, [])

	for alias: String in aliases:
		_remove_entry_alias(alias)

	entries.erase(entry_key)

	return true


## This is an internal method.
## Erases an entry alias key based the given [param entry_key].
##
## Returns true if [param entry_key] lead to a value and the value
## was an alias.
##
## This method does not update the entry's alternative property.
func _remove_entry_alias(entry_key: String) -> bool:
	var value: Variant = entries.get(entry_key, null)

	if value == null or value is Dictionary:
		return false

	entries.erase(entry_key)

	return true


## Updates the glossary entry's name and related alias keys.
## The [param old_entry_key] is the old unique name of the entry.
## The [param new_entry_key] is the new unique name of the entry.
##
## This method fails if the [param old_entry_key] does not exist.

## Do not use this to update alternative names.
## In order to update alternative names, delete all with
## [method _remove_entry_alias] and then add them again with
## [method _add_entry_key_alias].
func replace_entry_key(old_entry_key: String, new_entry_key: String) -> void:
	var entry := get_entry(old_entry_key)

	if entry == null:
		return

	entry.name = new_entry_key

	entries.erase(old_entry_key)
	entries[new_entry_key] = entry


## Gets the glossary entry for the given [param entry_key].
## If there is no matching entry, an empty Dictionary will be returned.
## Valid glossary entry dictionaries will never be empty.
func get_entry(entry_key: String) -> Dictionary:
	var entry: Variant = entries.get(entry_key, {})

	# Handle alias value.
	if entry is String:
		entry = entries.get(entry, {})

	return entry


## This is an internal method.
## The [param entry_key] must be valid entry key for an entry.
## Adds the [param alias] as a valid entry key for that entry.
##
## Returns the index of the entry, -1 if the entry does not exist.
func _add_entry_key_alias(entry_key: String, alias: String) -> bool:
	var entry := get_entry(entry_key)
	var alias_entry := get_entry(alias)

	if not entry.is_empty() and alias_entry.is_empty():
		entries[alias] = entry_key
		return true

	return false


## Adds [param entry] to the glossary if it does not exist.
## If it does exist, returns false.
func try_add_entry(entry: Dictionary) -> bool:
	var entry_key: String = entry[NAME_PROPERTY]

	if entries.has(entry_key):
		return false

	entries[entry_key] = entry

	for alternative: String in entry.get(ALTERNATIVE_PROPERTY, []):
		entries[alternative.strip_edges()] = entry_key

	return true


## Returns an array of words that can trigger the glossary popup.
## This method respects whether translation is enabled or not.
## The words may be: The entry key and the alternative words.
func _get_word_options(entry_key: String) -> Array:
	var word_options: Array = []

	var translation_enabled: bool = ProjectSettings.get_setting("dialogic/translation/enabled", false)

	if not translation_enabled:
		word_options.append(entry_key)

		for alternative: String in get_entry(entry_key).get(ALTERNATIVE_PROPERTY, []):
			word_options.append(alternative.strip_edges())

		return word_options

	var translation_entry_key_id: String = get_property_translation_key(entry_key, NAME_PROPERTY)

	if translation_entry_key_id.is_empty():
		return []

	var translated_entry_key := tr(translation_entry_key_id)

	if not translated_entry_key == translation_entry_key_id:
		word_options.append(translated_entry_key)

	var translation_alternatives_id: String = get_property_translation_key(entry_key, ALTERNATIVE_PROPERTY)
	var translated_alternatives_str := tr(translation_alternatives_id)

	if not translated_alternatives_str == translation_alternatives_id:
		var translated_alternatives := translated_alternatives_str.split(",")

		for alternative: String in translated_alternatives:
			word_options.append(alternative.strip_edges())

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

	for translation_key: String in entries.keys():

		if translation_key.begins_with(RESOURCE_NAME_KEY):
			entries.erase(translation_key)

	_translation_keys.clear()


## Returns a key used to reference this glossary in the translation CSV file.
##
## Time complexity: O(1)
func get_property_translation_key(entry_key: String, property: String) -> String:
	var entry := get_entry(entry_key)

	if entry == null:
		return ""

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

