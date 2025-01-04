class_name DialogicTranslationGettextFile
extends DialogicTranslationFile
## Generates translation files in gettext format.

var translations: Array[PotEntry] = []

## Configured original locale.
var original_locale: String

## Locations of the source files included in this translation.
var locations: Array[String] = []


## There is no need to load the old file(s) here, because every locale has its own file
## and this class doens't touch them.
func _init(file_path: String, original_locale: String) -> void:
	super._init(file_path, original_locale)
	self.original_locale = original_locale


func _append(key: String, value: String, path: String, line_number: int = -1) -> void:
	var entry = PotEntry.new()
	entry.key = key
	entry.translation = value
	entry.locations.append(PotReference.new(path, line_number))
	translations.append(entry)


## gettext doesn't support separators so this is a no-op.
func _append_separator() -> void:
	pass


## Overwrites the .pot file and the .po file of the original locale with the current [member translations] array.
func update_file_on_disk() -> void:
	# Overwrite the POT file.
	var file = FileAccess.open(used_file_path, FileAccess.WRITE)
	_write_header(file)
	for entry in translations:
		_write_entry(file, entry, "")
	file.close()

	# Overwrite the original_locale PO file.
	file = FileAccess.open(used_file_path.trim_suffix(".pot") + "." + original_locale + ".po", FileAccess.WRITE)
	_write_header(file, original_locale)
	for entry in translations:
		_write_entry(file, entry)
	file.close()


# This is based on POTGenerator::_write_to_pot() which unfortunately isn't exposed to gdscript.
func _write_header(file: FileAccess, locale: String = "") -> void:
	var project_name = ProjectSettings.get("application/config/name");
	var language_header = locale if !locale.is_empty() else "LANGUAGE"
	file.store_line("# " + language_header + " translation for " + project_name + " for the following files:")

	locations.sort()
	for location in locations:
		file.store_line("# " + location)

	file.store_line("")
	file.store_line("#, fuzzy");
	file.store_line("msgid \"\"")
	file.store_line("msgstr \"\"")
	file.store_line("\"Project-Id-Version: " + project_name + "\\n\"")
	if !locale.is_empty():
		file.store_line("\"Language: " + locale + "\\n\"")
	file.store_line("\"MIME-Version: 1.0\\n\"")
	file.store_line("\"Content-Type: text/plain; charset=UTF-8\\n\"")
	file.store_line("\"Content-Transfer-Encoding: 8-bit\\n\"")


func _write_entry(file: FileAccess, entry: PotEntry, value: String = entry.translation) -> void:
	file.store_line("")

	entry.locations.sort_custom(func (a: String, b: String): return b > a)
	for location in entry.locations:
		file.store_line("#: " + location.as_str())

	_write_line(file, "msgid", entry.key)
	_write_line(file, "msgstr", value)


# This is based on POTGenerator::_write_msgid() which unfortunately isn't exposed to gdscript.
func _write_line(file: FileAccess, type: String, value: String) -> void:
	file.store_string(type + " ")
	if value.is_empty():
		file.store_line("\"\"")
		return

	var lines = value.split("\n")
	var last_line = lines[lines.size() - 1]
	var pot_line_count = lines.size()
	if last_line.is_empty():
		pot_line_count -= 1

	if pot_line_count > 1:
		file.store_line("\"\"")

	for i in range(0, lines.size() - 1):
		file.store_line("\"" + (lines[i] + "\n").json_escape() + "\"")

	if !last_line.is_empty():
		file.store_line("\"" + last_line.json_escape() + "\"")


func collect_lines_from_character(character: DialogicCharacter) -> void:
	super.collect_lines_from_character(character)
	locations.append(character.resource_path)


func collect_lines_from_glossary(glossary: DialogicGlossary) -> void:
	super.collect_lines_from_glossary(glossary)
	locations.append(glossary.resource_path)


func collect_lines_from_timeline(timeline: DialogicTimeline) -> void:
	super.collect_lines_from_timeline(timeline)
	locations.append(timeline.resource_path)


class PotReference:
	var path: String
	var line_number: int


	func _init(path: String, line_number: int) -> void:
		self.path = path
		self.line_number = line_number


	func as_str() -> String:
		var str = ""
		if path.contains(" "):
			str += "\u2068" + path.trim_prefix("res://").replace("\n", "\\n") + "\u2069"
		else:
			str += path.trim_prefix("res://").replace("\n", "\\n")

		if line_number >= 0:
			str += ":" + str(line_number)

		return str


class PotEntry:
	var key: String
	var translation: String
	var locations: Array[PotReference] = []
