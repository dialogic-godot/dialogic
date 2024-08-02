class_name DialogicTranslationFile
extends RefCounted
## Generates translation files for [class DialogicTimeline], [class DialogicGlossary] and [class DialogicCharacter].

## Whether this file was able to be loaded a defined
## file path.
var is_new_file: bool = false

## File path used to load the file.
var used_file_path: String

## The amount of events that were updated in the file.
var updated_rows: int = 0

## The amount of events that were added to the file.
var new_rows: int = 0


func _init(file_path: String, original_locale: String) -> void:
	used_file_path = file_path
	is_new_file = not FileAccess.file_exists(file_path)


## Append a new entry to the available translations.
func _append(_key: String, _value: String, _path: String, _line_number: int = -1) -> void:
	pass


## Appends a separator if supported by the format and enabled by the user.
func _append_separator() -> void:
	pass


## Clears the file on disk and writes the current translations to it.
func update_file_on_disk() -> void:
	pass


## Collects names from the given [param character] and adds them.
func collect_lines_from_character(character: DialogicCharacter) -> void:
	character.get_set_translation_id()

	# Add row for display names.
	var name_property := DialogicCharacter.TranslatedProperties.NAME
	var display_name_key: String = character.get_property_translation_key(name_property)
	var line_value: String = character.display_name
	_append(display_name_key, line_value, character.resource_path)

	var nicknames: Array = character.nicknames

	if not nicknames.is_empty():
		var nick_name_property := DialogicCharacter.TranslatedProperties.NICKNAMES
		var nickname_string: String = ",".join(nicknames)
		var nickname_name_line_key: String = character.get_property_translation_key(nick_name_property)
		_append(nickname_name_line_key, nickname_string, character.resource_path)

	# New character item, if needed, add a separator.
	_append_separator()


## Returns whether [param value_b] is greater than [param value_a].
##
## This method helps to sort glossary entry properties by their importance
## matching the order in the editor.
##
## TODO: Allow Dialogic users to define their own order.
func _sort_glossary_entry_property_keys(property_key_a: String, property_key_b: String) -> bool:
	const GLOSSARY_LINE_ORDER := {
		DialogicGlossary.NAME_PROPERTY: 0,
		DialogicGlossary.ALTERNATIVE_PROPERTY: 1,
		DialogicGlossary.TEXT_PROPERTY: 2,
		DialogicGlossary.EXTRA_PROPERTY: 3,
	}
	const UNKNOWN_PROPERTY_ORDER := 100

	var value_a: int = GLOSSARY_LINE_ORDER.get(property_key_a, UNKNOWN_PROPERTY_ORDER)
	var value_b: int = GLOSSARY_LINE_ORDER.get(property_key_b, UNKNOWN_PROPERTY_ORDER)

	return value_a < value_b


## Collects properties from glossary entries from the given [param glossary] and
## adds them.
func collect_lines_from_glossary(glossary: DialogicGlossary) -> void:

	for glossary_value: Variant in glossary.entries.values():

		if glossary_value is String:
			continue

		var glossary_entry: Dictionary = glossary_value
		var glossary_entry_name: String = glossary_entry[DialogicGlossary.NAME_PROPERTY]

		var _glossary_translation_id := glossary.get_set_glossary_translation_id()
		var entry_translation_id := glossary.get_set_glossary_entry_translation_id(glossary_entry_name)

		var entry_property_keys := glossary_entry.keys().duplicate()
		entry_property_keys.sort_custom(_sort_glossary_entry_property_keys)

		var entry_name_property: String = glossary_entry[DialogicGlossary.NAME_PROPERTY]

		for entry_key: String in entry_property_keys:
			# Ignore private keys.
			if entry_key.begins_with(DialogicGlossary.PRIVATE_PROPERTY_PREFIX):
				continue

			var item_value: Variant = glossary_entry[entry_key]
			var item_value_str := ""

			if item_value is Array:
				var item_array := item_value as Array
				# We use a space after the comma to make it easier to read.
				item_value_str = ", ".join(item_array)

			elif not item_value is String or item_value.is_empty():
				continue

			else:
				item_value_str = item_value

			var glossary_key := glossary._get_glossary_translation_key(entry_translation_id, entry_key)

			if (entry_key == DialogicGlossary.NAME_PROPERTY
			or entry_key == DialogicGlossary.ALTERNATIVE_PROPERTY):
				glossary.entries[glossary_key] = entry_name_property

			_append(glossary_key, item_value_str, glossary.resource_path, -1)

		# New glossary item, if needed, add a separator.
		_append_separator()


## Collects translatable events from the given [param timeline] and adds
## them.
func collect_lines_from_timeline(timeline: DialogicTimeline) -> void:
	for event: DialogicEvent in timeline.events:

		if event.can_be_translated():

			if event._translation_id.is_empty():
				event.add_translation_id()
				event.update_text_version()

			var properties: Array = event._get_translatable_properties()

			for property: String in properties:
				var line_key: String = event.get_property_translation_key(property)
				var line_value: String = event._get_property_original_translation(property)
				_append(line_key, line_value, event.source_path, event.source_line_number)

	# End of timeline, if needed, add a separator.
	_append_separator()
