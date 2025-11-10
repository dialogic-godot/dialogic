class_name DialogicCsvFile
extends RefCounted
## Handles translation of a [class DialogicTimeline] to a CSV file.

var lines: Array[PackedStringArray] = []
## Dictionary of lines from the original file.
## Key: String, Value: PackedStringArray
var old_lines: Dictionary = {}

## The amount of columns the CSV file has after loading it.
## Used to add trailing commas to new lines.
var column_count := 0

## Whether this CSV file was able to be loaded a defined
## file path.
var is_new_file: bool = false

## The underlying file used to read and write the CSV file.
var file: FileAccess

## File path used to load the CSV file.
var used_file_path: String

## The amount of events that were updated in the CSV file.
var updated_rows: int = 0

## The amount of events that were added to the CSV file.
var new_rows: int = 0

## Whether this CSV handler should add newlines as a separator between sections.
## A section may be a new character, new timeline, or new glossary item inside
## a per-project file.
var add_separator: bool = false

enum PropertyType {
	String = 0,
	Array = 1,
	Other = 2,
}

## The translation property used for the glossary item translation.
const TRANSLATION_ID := DialogicGlossary.TRANSLATION_PROPERTY

## Attempts to load the CSV file from [param file_path].
## If the file does not exist, a single entry is added to the [member lines]
## array.
## The [param separator_enabled] enables adding newlines as a separator to
## per-project files. This is useful for readability.
func _init(file_path: String, original_locale: String, separator_enabled: bool) -> void:
	used_file_path = file_path
	add_separator = separator_enabled

	# The first entry must be the locale row.
	# [method collect_lines_from_timeline] will add the other locales, if any.
	var locale_array_line := PackedStringArray(["keys", original_locale])
	lines.append(locale_array_line)

	if not ResourceLoader.exists(file_path):
		is_new_file = true

		# The "keys" and original locale are the only columns in a new file.
		# For example: "keys, en"
		column_count = 2
		return

	file = FileAccess.open(file_path, FileAccess.READ)

	var locale_csv_row := file.get_csv_line()
	column_count = locale_csv_row.size()
	var locale_key := locale_csv_row[0]

	old_lines[locale_key] = locale_csv_row

	_read_file_into_lines()


## Private function to read the CSV file into the [member lines] array.
## Cannot be called on a new file.
func _read_file_into_lines() -> void:
	while not file.eof_reached():
		var line := file.get_csv_line()
		var row_key := line[0]

		old_lines[row_key] = line


## Collects names from the given [param characters] and adds them to the
## [member lines].
##
## If this is the character name CSV file, use this method to
## take previously collected characters from other [class DialogicCsvFile]s.
func collect_lines_from_characters(characters: Dictionary) -> void:
	for character: DialogicCharacter in characters.values():
		# Add row for display names.
		var name_property := DialogicCharacter.TranslatedProperties.NAME
		var display_name_key: String = character.get_property_translation_key(name_property)
		var line_value: String = character.display_name
		var array_line := PackedStringArray([display_name_key, line_value])
		lines.append(array_line)

		var nicknames: Array = character.nicknames

		if not nicknames.is_empty():
			var nick_name_property := DialogicCharacter.TranslatedProperties.NICKNAMES
			var nickname_string: String = ",".join(nicknames)
			var nickname_name_line_key: String = character.get_property_translation_key(nick_name_property)
			var nick_array_line := PackedStringArray([nickname_name_line_key, nickname_string])
			lines.append(nick_array_line)

		# New character item, if needed, add a separator.
		if add_separator:
			_append_empty()


## Appends an empty line to the [member lines] array.
func _append_empty() -> void:
	var empty_line := PackedStringArray(["", ""])
	lines.append(empty_line)


## Returns the property type for the given [param key].
func _get_key_type(key: String) -> PropertyType:
	if key.ends_with(DialogicGlossary.NAME_PROPERTY):
		return PropertyType.String

	if key.ends_with(DialogicGlossary.ALTERNATIVE_PROPERTY):
		return PropertyType.Array

	return PropertyType.Other


func _process_line_into_array(csv_values: PackedStringArray, property_type: PropertyType) -> Array[String]:
	const KEY_VALUE_INDEX := 0
	var values_as_array: Array[String] = []

	for i in csv_values.size():

		if i == KEY_VALUE_INDEX:
			continue

		var csv_value := csv_values[i]

		if csv_value.is_empty():
			continue

		match property_type:
			PropertyType.String:
				values_as_array = [csv_value]

			PropertyType.Array:
				var split_values := csv_value.split(",")

				for value in split_values:
					values_as_array.append(value)

	return values_as_array


func _add_keys_to_glossary(glossary: DialogicGlossary, names: Array) -> void:
	var glossary_prefix_key := glossary._get_glossary_translation_id_prefix()
	var glossary_translation_id_prefix := _get_glossary_translation_key_prefix(glossary)

	for glossary_line: PackedStringArray in names:

		if glossary_line.is_empty():
			continue

		var csv_key := glossary_line[0]

		# CSV line separators will be empty.
		if not csv_key.begins_with(glossary_prefix_key):
			continue

		var value_type := _get_key_type(csv_key)

		# String and Array are the only valid types.
		if (value_type == PropertyType.Other
		or not csv_key.begins_with(glossary_translation_id_prefix)):
			continue

		var new_line_to_add := _process_line_into_array(glossary_line, value_type)

		for name_to_add: String in new_line_to_add:
			glossary._translation_keys[name_to_add.strip_edges()] = csv_key



## Reads all [member lines] and adds them to the given [param glossary]'s
## internal collection of words-to-translation-key mappings.
##
## Populate the CSV's lines with the method [method collect_lines_from_glossary]
## before.
func add_translation_keys_to_glossary(glossary: DialogicGlossary) -> void:
	glossary._translation_keys.clear()
	_add_keys_to_glossary(glossary, lines)
	_add_keys_to_glossary(glossary, old_lines.values())


## Returns the translation key prefix for the given [param glossary_translation_id].
## The resulting format will look like this: Glossary/a2/
## You can use this to find entries in [member lines] that to a glossary.
func _get_glossary_translation_key_prefix(glossary: DialogicGlossary) -> String:
	return (
		DialogicGlossary.RESOURCE_NAME
			.path_join(glossary._translation_id)
	)


## Returns whether [param value_b] is greater than [param value_a].
##
## This method helps to sort glossary entry properties by their importance
## matching the order in the editor.
##
## TODO: Allow Dialogic users to define their own order.
func _sort_glossary_entry_property_keys(property_key_a: String, property_key_b: String) -> bool:
	const GLOSSARY_CSV_LINE_ORDER := {
		DialogicGlossary.NAME_PROPERTY: 0,
		DialogicGlossary.ALTERNATIVE_PROPERTY: 1,
		DialogicGlossary.TEXT_PROPERTY: 2,
		DialogicGlossary.EXTRA_PROPERTY: 3,
	}
	const UNKNOWN_PROPERTY_ORDER := 100

	var value_a: int = GLOSSARY_CSV_LINE_ORDER.get(property_key_a, UNKNOWN_PROPERTY_ORDER)
	var value_b: int = GLOSSARY_CSV_LINE_ORDER.get(property_key_b, UNKNOWN_PROPERTY_ORDER)

	return value_a < value_b


## Collects properties from glossary entries from the given [param glossary] and
## adds them to the [member lines].
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
				item_value_str = " ,".join(item_array)

			elif not item_value is String or item_value.is_empty():
				continue

			else:
				item_value_str = item_value

			var glossary_csv_key := glossary._get_glossary_translation_key(entry_translation_id, entry_key)

			if (entry_key == DialogicGlossary.NAME_PROPERTY
			or entry_key == DialogicGlossary.ALTERNATIVE_PROPERTY):
				glossary.entries[glossary_csv_key] = entry_name_property

			var glossary_line := PackedStringArray([glossary_csv_key, item_value_str])

			lines.append(glossary_line)

		# New glossary item, if needed, add a separator.
		if add_separator:
			_append_empty()



## Collects translatable events from the given [param timeline] and adds
## them to the [member lines].
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
				var array_line := PackedStringArray([line_key, line_value])
				lines.append(array_line)

	# End of timeline, if needed, add a separator.
	if add_separator:
		_append_empty()


## Clears the CSV file on disk and writes the current [member lines] array to it.
## Uses the [member old_lines] dictionary to update existing translations.
## If a translation row misses a column, a trailing comma will be added to
## conform to the CSV file format.
##
## If the locale CSV line was collected only, a new file won't be created and
## already existing translations won't be updated.
func update_csv_file_on_disk() -> void:
	# None or locale row only.
	if lines.size() < 2:
		print_rich("[color=yellow]No lines for the CSV file, skipping: " + used_file_path)

		return

	# Clear the current CSV file.
	file = FileAccess.open(used_file_path, FileAccess.WRITE)

	for line in lines:
		var row_key := line[0]

		# In case there might be translations for this line already,
		# add them at the end again (orig locale text is replaced).
		if row_key in old_lines:
			var old_line: PackedStringArray = old_lines[row_key]
			var updated_line: PackedStringArray = line + old_line.slice(2)

			var line_columns: int = updated_line.size()
			var line_columns_to_add := column_count - line_columns

			# Add trailing commas to match the amount of columns.
			for _i in range(line_columns_to_add):
				updated_line.append("")

			file.store_csv_line(updated_line)
			updated_rows += 1

		else:
			var line_columns: int = line.size()
			var line_columns_to_add := column_count - line_columns

			# Add trailing commas to match the amount of columns.
			for _i in range(line_columns_to_add):
				line.append("")

			file.store_csv_line(line)
			new_rows += 1

	file.close()
