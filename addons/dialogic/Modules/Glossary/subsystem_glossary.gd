extends DialogicSubsystem

## Subsystem that handles glossaries.

## List of glossary resources that are used.
var glossaries := []
## If false, no parsing will be done.
var enabled := true

## Any key in this dictionary will overwrite the color for any item with that name.
var color_overrides := {}


####################################################################################################
##					STATE
####################################################################################################

func clear_game_state(_clear_flag := Dialogic.ClearFlags.FULL_CLEAR) -> void:
	glossaries = []

	for path: String in ProjectSettings.get_setting('dialogic/glossary/glossary_files', []):
		add_glossary(path)


####################################################################################################
##					MAIN METHODS
####################################################################################################

func parse_glossary(text: String) -> String:
	if not enabled:
		return text

	var def_case_sensitive:bool = ProjectSettings.get_setting('dialogic/glossary/default_case_sensitive', true)
	var def_color: Color = ProjectSettings.get_setting('dialogic/glossary/default_color', Color.POWDER_BLUE)
	var regex := RegEx.new()

	for glossary: DialogicGlossary in glossaries:

		if !glossary.enabled:
			continue

		for entry: Dictionary in glossary.entries:
			var entry_key: String = entry[DialogicGlossary.NAME_PROPERTY]

			if not entry.get('enabled', true):
				continue

			var regex_options := glossary.get_set_regex_option(entry_key)
			var pattern: String = "(?<=\\W|^)(?<word>" + regex_options + ")(?!])(?=\\W|$)"

			if entry.get('case_sensitive', def_case_sensitive):
				regex.compile(pattern)

			else:
				regex.compile('(?i)'+pattern)

			var color: String = entry.get('color', def_color).to_html()

			if entry_key in color_overrides:
				color = color_overrides[entry_key].to_html()

			text = regex.sub(text,
				'[url=' + entry_key + ']' +
				'[color=' + color + ']${word}[/color]' +
				'[/url]', true
				)

	return text


func add_glossary(path:String) -> void:
	if ResourceLoader.exists(path):
		var resource: DialogicGlossary = load(path)

		if resource is DialogicGlossary:
			glossaries.append(resource)
	else:
		printerr('[Dialogic] The glossary file "' + path + '" is missing. Make sure it exists.')


## Iterates over all glossaries and returns the first one that matches the
## [param entry_key].
##
## Returns null if none of the glossaries has an entry with that key.
## If translation is enabled, uses the [param entry_key] as well to check
## [member _translation_keys].
##
## Runtime complexity:
## O(n), where n is the number of glossaries.
func find_glossary(entry_key: String) -> DialogicGlossary:
	for glossary: DialogicGlossary in glossaries:

		if glossary._entry_keys.has(entry_key):
			return glossary

		if glossary._translation_keys.has(entry_key):
			return glossary

	return null
