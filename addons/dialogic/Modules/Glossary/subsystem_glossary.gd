extends DialogicSubsystem

## Subsystem that handles glossaries.

## List of glossary resources that are used.
var glossaries := []
## If false, no parsing will be done.
var enabled := true

## Any key in this dictionary will overwrite the color for any item with that name.
var color_overrides := {}

const SETTING_DEFAULT_COLOR := 'dialogic/glossary/default_color'


#region STATE
####################################################################################################

func clear_game_state(_clear_flag := DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	glossaries = []

	for path: String in ProjectSettings.get_setting('dialogic/glossary/glossary_files', []):
		add_glossary(path)

#endregion


#region MAIN METHODS
####################################################################################################

func parse_glossary(text: String) -> String:
	if not enabled:
		return text

	var def_case_sensitive: bool = ProjectSettings.get_setting('dialogic/glossary/default_case_sensitive', true)
	var def_color: Color = ProjectSettings.get_setting(SETTING_DEFAULT_COLOR, Color.POWDER_BLUE)
	var regex := RegEx.new()

	for glossary: DialogicGlossary in glossaries:

		if !glossary.enabled:
			continue

		for entry_value: Variant in glossary.entries.values():

			if not entry_value is Dictionary:
				continue

			var entry: Dictionary = entry_value
			var entry_key: String = entry.get(DialogicGlossary.NAME_PROPERTY, "")

			# Older versions of the glossary resource do not have a property
			# for their name, we must skip these.
			# They can be updated by opening the resource in the glossary
			# editor.
			if entry_key.is_empty():
				continue

			if not entry.get('enabled', true):
				continue

			var regex_options := glossary.get_set_regex_option(entry_key)

			if regex_options.is_empty():
				continue

			var pattern: String = r'(?<=\W|^)(?<!\\)(?<word>' + regex_options + r')(?!])(?=\W|$)'

			if entry.get('case_sensitive', def_case_sensitive):
				regex.compile(pattern)

			else:
				regex.compile('(?i)'+pattern)

			var color: String = entry.get('color', def_color).to_html()

			if entry_key in color_overrides:
				color = color_overrides[entry_key].to_html()

			text = regex.sub(text,
				'[url="' + entry_key + '"]' +
				'[color=' + color + ']${word}[/color]' +
				'[/url]',
				true
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
## Runtime complexity:
## O(n), where n is the number of glossaries.
func find_glossary(entry_key: String) -> DialogicGlossary:
	for glossary: DialogicGlossary in glossaries:

		if glossary.entries.has(entry_key):
			return glossary

	return null


## Returns the first match for a given entry key.
## If translation is available and enabled, it will be translated
func get_entry(entry_key: String) -> Dictionary:
	var glossary: DialogicGlossary = dialogic.Glossary.find_glossary(entry_key)

	var result := {
		"title": "",
		"text": "",
		"extra": "",
		"color": Color.WHITE,
		}

	if glossary == null:
		return {}

	var is_translation_enabled: bool = ProjectSettings.get_setting('dialogic/translation/enabled', false)

	var entry := glossary.get_entry(entry_key)

	if entry.is_empty():
		return {}

	result.color = entry.get("color")
	if result.color == null:
		result.color = ProjectSettings.get_setting(SETTING_DEFAULT_COLOR, Color.POWDER_BLUE)

	if is_translation_enabled and not glossary._translation_id.is_empty():
		var translation_key: String = glossary._translation_keys.get(entry_key)
		var last_slash := translation_key.rfind('/')

		if last_slash == -1:
			return {}

		var tr_base := translation_key.substr(0, last_slash)

		result.title = translate(tr_base, "title", entry)
		result.text = translate(tr_base, "text", entry)
		result.extra = translate(tr_base, "extra", entry)
	else:
		result.title = entry.get("title", "")
		result.text = entry.get("text", "")
		result.extra = entry.get("extra", "")

	## PARSE TEXTS FOR VARIABLES
	result.title = dialogic.VAR.parse_variables(result.title)
	result.text = dialogic.VAR.parse_variables(result.text)
	result.extra = dialogic.VAR.parse_variables(result.extra)

	return result



## Tries to translate the property with the given
func translate(tr_base: String, property: StringName, fallback_entry: Dictionary) -> String:
	var tr_key := tr_base.path_join(property)
	var tr_value := tr(tr_key)

	if tr_key == tr_value:
		tr_value = fallback_entry.get(property, "")

	return tr_value
