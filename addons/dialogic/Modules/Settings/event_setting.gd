@tool
class_name DialogicSettingEvent
extends DialogicEvent

## Event that allows changing a specific setting.


### Settings

enum Modes {SET, RESET, RESET_ALL}
enum SettingValueType {
	STRING,
	NUMBER,
	VARIABLE,
	EXPRESSION
}

## The name of the setting to save to.
var name: String = ""
var _value_type := 0 :
	get:
		return _value_type
	set(_value):
		_value_type = _value
		if not _suppress_default_value: 
			match _value_type:
				SettingValueType.STRING, SettingValueType.VARIABLE, SettingValueType.EXPRESSION:
					value = ""
				SettingValueType.NUMBER:
					value = 0
			ui_update_needed.emit()
			
var value: Variant = ""

var mode := Modes.SET

## Used to suppress _value_type from overwriting value with a default value when the type changes
## This is only used when initializing the event_variable.
var _suppress_default_value: bool = false

################################################################################
## 						INITIALIZE
################################################################################

func _execute() -> void:
	if mode == Modes.RESET or mode == Modes.RESET_ALL:
		if !name.is_empty() and mode != Modes.RESET_ALL:
			dialogic.Settings.reset_setting(name)
		else:
			dialogic.Settings.reset_all()
	else:
		match _value_type:
			SettingValueType.STRING:
				dialogic.Settings.set(name, value)
			SettingValueType.NUMBER:
				dialogic.Settings.set(name, float(value))
			SettingValueType.VARIABLE:
				if dialogic.has_subsystem('VAR'):
					dialogic.Settings.set(name, dialogic.VAR.get_variable('{'+value+'}'))
			SettingValueType.EXPRESSION:
				if dialogic.has_subsystem('VAR'):
					dialogic.Settings.set(name, dialogic.VAR.get_variable(value))
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Setting"
	set_default_color('Color9')
	event_category = "Helpers"
	event_sorting_index = 2


func _get_icon() -> Resource:
	return load(self.get_script().get_path().get_base_dir().path_join('icon.svg'))


################################################################################
## 						SAVING/LOADING
################################################################################

func to_text() -> String:
	var string := "setting "
	if mode != Modes.SET:
		string += "reset "

	if !name.is_empty() and mode != Modes.RESET_ALL:
		string += '"' + name + '"'

	if mode == Modes.SET:
		string += " = "
		value = str(value)
		match _value_type:
			SettingValueType.STRING: # String
				string += '"'+value.replace('"', '\\"')+'"'
			SettingValueType.NUMBER,SettingValueType.EXPRESSION: # Float or Expression
				string += str(value)
			SettingValueType.VARIABLE: # Variable
				string += '{'+value+'}'

	return string


func from_text(string:String) -> void:
	var reg := RegEx.new()
	reg.compile('setting (?<reset>reset)? *("(?<name>[^=+\\-*\\/]*)")?( *= *(?<value>.*))?')
	var result := reg.search(string)
	if !result:
		return

	if result.get_string('reset'):
		mode = Modes.RESET

	name = result.get_string('name').strip_edges()

	if name.is_empty() and mode == Modes.RESET:
		mode = Modes.RESET_ALL

	if result.get_string('value'):
		_suppress_default_value = true
		value = result.get_string('value').strip_edges()
		if value.begins_with('"') and value.ends_with('"') and value.count('"')-value.count('\\"') == 2:
			value = result.get_string('value').strip_edges().replace('"', '')
			_value_type = SettingValueType.STRING
		elif value.begins_with('{') and value.ends_with('}') and value.count('{') == 1:
			value = result.get_string('value').strip_edges().trim_suffix('}').trim_prefix('{')
			_value_type = SettingValueType.VARIABLE
		else:
			value = result.get_string('value').strip_edges()
			if value.is_valid_float():
				_value_type = SettingValueType.NUMBER
			else:
				_value_type = SettingValueType.EXPRESSION
		_suppress_default_value = false


func is_valid_event(string:String) -> bool:
	return string.begins_with('setting')


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('mode', ValueType.FIXED_OPTIONS, {
		'options': [{
				'label': 'Set',
				'value': Modes.SET,
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/default.svg")
			},{
				'label': 'Reset',
				'value': Modes.RESET,
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/update.svg")
			},{
				'label': 'Reset All',
				'value': Modes.RESET_ALL,
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/update.svg")
			},
			]})

	add_header_edit('name', ValueType.DYNAMIC_OPTIONS, {'placeholder':'Type setting', 'suggestions_func':get_settings_suggestions}, 'mode != Modes.RESET_ALL')
	add_header_edit('_value_type', ValueType.FIXED_OPTIONS, {'left_text':'to',
		'options': [
			{
				'label': 'String',
				'icon': ["String", "EditorIcons"],
				'value': SettingValueType.STRING
			},{
				'label': 'Number',
				'icon': ["float", "EditorIcons"],
				'value': SettingValueType.NUMBER
			},{
				'label': 'Variable',
				'icon': ["ClassList", "EditorIcons"],
				'value': SettingValueType.VARIABLE
			},{
				'label': 'Expression',
				'icon': ["Variant", "EditorIcons"],
				'value': SettingValueType.EXPRESSION
			}],
		'symbol_only':true},
		'!name.is_empty() and mode == Modes.SET')
	add_header_edit('value', ValueType.SINGLELINE_TEXT, {}, '!name.is_empty() and (_value_type == SettingValueType.STRING or _value_type == SettingValueType.EXPRESSION) and mode == Modes.SET')
	add_header_edit('value', ValueType.NUMBER, {}, '!name.is_empty()  and _value_type == SettingValueType.NUMBER and mode == Modes.SET')
	add_header_edit('value', ValueType.DYNAMIC_OPTIONS,
			{'suggestions_func' : get_value_suggestions, 'placeholder':'Select Variable'},
			'!name.is_empty() and _value_type == SettingValueType.VARIABLE and mode == Modes.SET')


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



####################### CODE COMPLETION ########################################
################################################################################

func _get_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit, line:String, word:String, symbol:String) -> void:
	if symbol == " " and !"reset" in line and !'=' in line and !'"' in line:
		TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, "reset", "reset ", event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.5), TextNode.get_theme_icon("RotateLeft", "EditorIcons"))
		TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, "reset all", "reset \n", event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.5), TextNode.get_theme_icon("ToolRotate", "EditorIcons"))

	if (symbol == " " or symbol == '"') and !"=" in line and CodeCompletionHelper.get_line_untill_caret(line).count('"') != 2:
		for i in get_settings_suggestions(''):
			if i.is_empty():
				continue
			if symbol == '"':
				TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, i, i, event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.5), TextNode.get_theme_icon("GDScript", "EditorIcons"), '"')
			else:
				TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, i, '"'+i, event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.5), TextNode.get_theme_icon("GDScript", "EditorIcons"), '"')


func _get_start_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit) -> void:
	TextNode.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'setting', 'setting ', event_color)

#################### SYNTAX HIGHLIGHTING #######################################
################################################################################

func _get_syntax_highlighting(Highlighter:SyntaxHighlighter, dict:Dictionary, line:String) -> Dictionary:
	dict[line.find('setting')] = {"color":event_color}
	dict[line.find('setting')+7] = {"color":Highlighter.normal_color}
	dict = Highlighter.color_word(dict, event_color, line, 'reset')
	dict = Highlighter.color_region(dict, Highlighter.string_color, line, '"', '"')
	dict = Highlighter.color_region(dict, Highlighter.variable_color, line, '{', '}')
	return dict
