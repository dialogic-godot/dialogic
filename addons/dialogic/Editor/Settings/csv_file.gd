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
var updated_events: int = 0

## The amount of events that were added to the CSV file.
var new_events: int = 0

## Attempts to load the CSV file from [param file_path].
## If the file does not exist, a single entry is added to the [member lines]
## array.
func _init(file_path: String, original_locale: String) -> void:
    used_file_path = file_path

    # The first entry must be the locale row.
    # [method collect_lines_from_timeline] will add the other locales, if any.
    var locale_array_line := PackedStringArray(["keys", original_locale])
    lines.append(locale_array_line)

    if not FileAccess.file_exists(file_path):
        is_new_file = true

        # The "keys" and original locale are the only columns in a new file.
        # For example: "keys, en"
        column_count = 2

        file = FileAccess.open(file_path, FileAccess.WRITE)
        return

    file = FileAccess.open(file_path, FileAccess.READ)

    var locale_csv_row := file.get_csv_line()
    column_count = locale_csv_row.size()
    var locale_key := locale_csv_row[0]

    old_lines[locale_key] = locale_csv_row

    _read_file_into_lines()


## Private function to read the CSV file into the [member lines] array.
func _read_file_into_lines() -> void:
    while not file.eof_reached():
        var line := file.get_csv_line()
        var row_key := line[0]
        old_lines[row_key] = line


func collect_lines_from_timeline(timeline: DialogicTimeline) -> void:
    for event in timeline.events:

        if event.can_be_translated():

            if event._translation_id.is_empty():
                event.add_translation_id()
                event.update_text_version()

            for property in event._get_translatable_properties():
                var line_key: String = event.get_property_translation_key(property)
                var line_value: String = event._get_property_original_translation(property)
                var array_line := PackedStringArray([line_key, line_value])
                lines.append(array_line)


## Clears the CSV file on disk and writes the current [member lines] array to it.
## Uses the [member old_lines] dictionary to update existing translations.
## If a translation row misses a column, a trailing comma will be added to
## conform to the CSV file format.
func update_csv_file_on_disk() -> void:
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
            updated_events += 1

        else:
            var line_columns: int = line.size()
            var line_columns_to_add := column_count - line_columns

            # Add trailing commas to match the amount of columns.
            for _i in range(line_columns_to_add):
                line.append("")

            file.store_csv_line(line)
            new_events += 1

    file.close()
