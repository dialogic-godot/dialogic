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

		for entry_key: String in glossary.entries.keys():
			var entry: Dictionary = glossary.entries.get(entry_key, {})

			if not entry.get('enabled', true):
				continue

			var regex_options := glossary.get_set_regex_option(entry_key)
			var pattern: String = "(?<=\\W|^)(?<word>" + regex_options + ")(?!])(?=\\W|$)"

			if entry.get('case_sensitive', def_case_sensitive):
				regex.compile(pattern)

			else:
				regex.compile('(?i)'+pattern)

			var color: String = glossary.entries[entry_key].get('color', def_color).to_html()

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


## The translation key base is the first part of a glossary entry key.

func get_translation_key_base(entry_key: String, _entry_parse_variables: bool = true) -> String:
	for glossary: DialogicGlossary in glossaries:

		if not glossary._translation_keys.has(entry_key):
			continue

		return glossary.get_word_translation_key(entry_key)

	return ""
