@tool
class_name DialogicSettingEvent
extends DialogicEvent

## Event that allows changing a specific setting.


### Settings

enum Modes {Set, Reset, ResetAll}

## The name of the setting to save to. 
var name: String = ""
var _value_type := 0
var value: Variant = ""

var mode := Modes.Set

################################################################################
## 						INITIALIZE
################################################################################

func _execute() -> void:
	if mode == Modes.Reset or mode == Modes.ResetAll:
		if !name.is_empty() and mode != Modes.ResetAll:
			dialogic.Settings.reset_setting(name)
		else:
			dialogic.Settings.reset_all()
	else:
		match _value_type:
			0:
				dialogic.Settings.set(name, value)
			1:
				dialogic.Settings.set(name, float(value))
			2:
				if dialogic.has_subsystem('VAR'):
					dialogic.Settings.set(name, dialogic.VAR.get_variable('{'+value+'}'))
			3:
				if dialogic.has_subsystem('VAR'):
					dialogic.Settings.set(name, dialogic.VAR.get_variable(value))
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Setting"
	set_default_color('Color6')
	event_category = "Helpers"
	event_sorting_index = 2


func _get_icon() -> Resource:
	return load(self.get_script().get_path().get_base_dir().path_join('icon.svg'))


################################################################################
## 						SAVING/LOADING
################################################################################

func to_text() -> String:
	var string := "Setting "
	if mode == Modes.Reset:
		string += "reset "
	
	if !name.is_empty() and mode != Modes.ResetAll:
		string += '"' + name + '"'
	
	if mode == Modes.Set:
		string += " = "
		value = str(value)
		match _value_type:
			0: # String
				string += '"'+value.replace('"', '\\"')+'"'
			1,3: # Float or Expression
				string += str(value)
			2: # Variable
				string += '{'+value+'}'
	
	return string


func from_text(string:String) -> void:
	var reg := RegEx.new()
	reg.compile('Setting (?<reset>reset)? *("(?<name>[^=+\\-*\\/]*)")?( *= *(?<value>.*))?')
	var result := reg.search(string)
	if !result:
		return
	
	if result.get_string('reset'):
		mode = Modes.Reset
	
	name = result.get_string('name').strip_edges()
	
	if name.is_empty() and mode == Modes.Reset:
		mode = Modes.ResetAll
	
	if result.get_string('value'):
		value = result.get_string('value').strip_edges()
		if value.begins_with('"') and value.ends_with('"') and value.count('"')-value.count('\\"') == 2:
			value = result.get_string('value').strip_edges().replace('"', '')
			_value_type = 0
		elif value.begins_with('{') and value.ends_with('}') and value.count('{') == 1:
			value = result.get_string('value').strip_edges().trim_suffix('}').trim_prefix('{')
			_value_type = 2
		else:
			value = result.get_string('value').strip_edges()
			if value.is_valid_float():
				_value_type = 1
			else:
				_value_type = 3


func is_valid_event(string:String) -> bool:
	return string.begins_with('Setting')


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('mode', ValueType.FixedOptionSelector, '', '', {
		'selector_options': [{
				'label': 'Set',
				'value': Modes.Set,
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/default.svg")
			},{
				'label': 'Reset',
				'value': Modes.Reset,
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/update.svg")
			},{
				'label': 'Reset All',
				'value': Modes.ResetAll,
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/update.svg")
			},
			]})
	
	add_header_edit('name', ValueType.ComplexPicker, '', '', {'placeholder':'Type setting', 'suggestions_func':get_settings_suggestions}, 'mode != 2')
	add_header_edit('_value_type', ValueType.FixedOptionSelector, 'to', '', {
		'selector_options': [
			{
				'label': 'String',
				'icon': ["String", "EditorIcons"],
				'value': 0
			},{
				'label': 'Number',
				'icon': ["float", "EditorIcons"],
				'value': 1
			},{
				'label': 'Variable',
				'icon': ["ClassList", "EditorIcons"],
				'value': 2
			},{
				'label': 'Expression',
				'icon': ["Variant", "EditorIcons"],
				'value': 3
			}],
		'symbol_only':true}, 
		'!name.is_empty() and mode == 0')
	add_header_edit('value', ValueType.SinglelineText, '', '', {}, '!name.is_empty() and (_value_type == 0 or _value_type == 3) and mode == 0')
	add_header_edit('value', ValueType.Float, '', '', {}, '!name.is_empty()  and _value_type == 1 and mode == 0')
	add_header_edit('value', ValueType.ComplexPicker, '', '', 
			{'suggestions_func' : get_value_suggestions, 'placeholder':'Select Variable'}, 
			'!name.is_empty() and _value_type == 2 and mode == 0')


func get_settings_suggestions(filter:String) -> Dictionary:
	var suggestions := {filter:{'value':filter, 'editor_icon':["GDScriptInternal", "EditorIcons"]}}
	
	for prop in ProjectSettings.get_property_list():
		if prop.name.begins_with('dialogic/settings/'):
			suggestions[prop.name.trim_prefix('dialogic/settings/')] = {'value':prop.name.trim_prefix('dialogic/settings/'), 'editor_icon':["GDScript", "EditorIcons"]}
	return suggestions


func get_value_suggestions(filter:String) -> Dictionary:
	var suggestions := {}
	
	var vars: Dictionary = ProjectSettings.get_setting('dialogic/variables', {})
	for var_path in DialogicUtil.list_variables(vars):
		suggestions[var_path] = {'value':var_path, 'editor_icon':["ClassList", "EditorIcons"]}
	return suggestions
