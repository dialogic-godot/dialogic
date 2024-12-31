class_name DialogicTranslationCsvFile
extends DialogicTranslationFile
## Generates translation files in CSV format.

var lines: Array[PackedStringArray] = []
## Dictionary of lines from the original file.
## Key: String, Value: PackedStringArray
var old_lines: Dictionary = {}

## The amount of columns the CSV file has after loading it.
## Used to add trailing commas to new lines.
var column_count := 0

## The underlying file used to read and write the CSV file.
var file: FileAccess

## Whether this CSV handler should add newlines as a separator between sections.
## A section may be a new character, new timeline, or new glossary item inside
## a per-project file.
var add_separator: bool = false


## Attempts to load the CSV file from [param file_path].
## If the file does not exist, a single entry is added to the [member lines]
## array.
## The [param separator_enabled] enables adding newlines as a separator to
## per-project files. This is useful for readability.
func _init(file_path: String, original_locale: String, separator_enabled: bool) -> void:
	super._init(file_path, original_locale)

	add_separator = separator_enabled

	# The first entry must be the locale row.
	# [method collect_lines_from_timeline] will add the other locales, if any.
	var locale_array_line := PackedStringArray(["keys", original_locale])
	lines.append(locale_array_line)

	if is_new_file:
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


func _append(key: String, value: String, _path: String, _line_number: int = -1) -> void:
	var array_line := PackedStringArray([key, value])
	lines.append(array_line)


## Appends an empty line to the [member lines] array.
func _append_separator() -> void:
	if add_separator:
		var empty_line := PackedStringArray(["", ""])
		lines.append(empty_line)


## Clears the CSV file on disk and writes the current [member lines] array to it.
## Uses the [member old_lines] dictionary to update existing translations.
## If a translation row misses a column, a trailing comma will be added to
## conform to the CSV file format.
##
## If the locale CSV line was collected only, a new file won't be created and
## already existing translations won't be updated.
func update_file_on_disk() -> void:
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
