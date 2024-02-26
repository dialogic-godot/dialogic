@tool
class_name DialogicVariableEvent
extends DialogicEvent

## Event that allows changing a dialogic variable or a property of an autoload.


enum Operations {SET, ADD, SUBSTRACT, MULTIPLY, DIVIDE}
enum VarValueType {
	STRING = 0,
	NUMBER = 1,
	VARIABLE = 2,
	BOOL = 3,
	EXPRESSION = 4,
	RANDOM_NUMBER = 5,
}

## Settings

## Name/Path of the variable that should be changed.
var name: String = "":
	set(_value):
		name = _value
		if Engine.is_editor_hint() and not value:
			match DialogicUtil.get_variable_type(name):
				DialogicUtil.VarTypes.ANY, DialogicUtil.VarTypes.STRING:
					_value_type = VarValueType.STRING
				DialogicUtil.VarTypes.FLOAT, DialogicUtil.VarTypes.INT:
					_value_type = VarValueType.NUMBER
				DialogicUtil.VarTypes.BOOL:
					_value_type = VarValueType.BOOL
			ui_update_needed.emit()
		update_editor_warning()
## The operation to perform.
var operation: int = Operations.SET:
	set(value):
		operation = value
		if operation != Operations.SET and _value_type == VarValueType.STRING:
			_value_type = VarValueType.NUMBER
			ui_update_needed.emit()
		update_editor_warning()

## The value that is used. Can be a variable as well.
var value: Variant = ""
var _value_type := 0 :
	set(_value):
		_value_type = _value
		if not _suppress_default_value:
			match _value_type:
				VarValueType.STRING, VarValueType.VARIABLE, VarValueType.EXPRESSION:
					value = ""
				VarValueType.NUMBER:
					value = 0
				VarValueType.BOOL:
					value = false
				VarValueType.RANDOM_NUMBER:
					value = null
			ui_update_needed.emit()
		update_editor_warning()

## If true, a random number between [random_min] and [random_max] is used instead of [value].
var random_min: int = 0
var random_max: int = 100

## Used to suppress _value_type from overwriting value with a default value when the type changes
## This is only used when initializing the event_variable.
var _suppress_default_value: bool = false


################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	if name:
		var orig: Variant = dialogic.VAR.get_variable(name)
		if value != null and orig != null:
			var the_value: Variant
			match _value_type:
				VarValueType.STRING:
					the_value = dialogic.VAR.get_variable('"'+value+'"')
				VarValueType.VARIABLE:
					the_value = dialogic.VAR.get_variable('{'+value+'}')
				VarValueType.NUMBER,VarValueType.BOOL,VarValueType.EXPRESSION,VarValueType.RANDOM_NUMBER:
					the_value = dialogic.VAR.get_variable(str(value))

			if operation != Operations.SET and str(orig).is_valid_float() and str(the_value).is_valid_float():
				orig = float(orig)
				the_value = float(the_value)
				match operation:
					Operations.ADD:
						dialogic.VAR.set_variable(name, orig+the_value)
					Operations.SUBSTRACT:
						dialogic.VAR.set_variable(name, orig-the_value)
					Operations.MULTIPLY:
						dialogic.VAR.set_variable(name, orig*the_value)
					Operations.DIVIDE:
						dialogic.VAR.set_variable(name, orig/the_value)
				dialogic.VAR.variable_was_set.emit({'variable':name, 'new_value':the_value, 'value':value})
			elif operation == Operations.SET:
				dialogic.VAR.set_variable(name, the_value)
				dialogic.VAR.variable_was_set.emit({'variable':name, 'new_value':the_value, 'value':value})
			else:
				printerr("Dialogic: Set Variable event failed because one value wasn't a float! [", orig, ", ",the_value,"]")
		else:
			printerr("Dialogic: Set Variable event failed because one value wasn't set!")

	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Set Variable"
	set_default_color('Color6')
	event_category = "Logic"
	event_sorting_index = 0
	help_page_path = "https://docs.dialogic.pro/variables.html#23-set-variable-event"


################################################################################
## 						SAVING/LOADING
################################################################################

func to_text() -> String:
	var string := "set "
	if name:
		string += "{" + name + "}"
		match operation:
			Operations.SET:
				string+= " = "
			Operations.ADD:
				string+= " += "
			Operations.SUBSTRACT:
				string+= " -= "
			Operations.MULTIPLY:
				string+= " *= "
			Operations.DIVIDE:
				string+= " /= "

		value = str(value)
		match _value_type:
			VarValueType.STRING: # String
				string += '"'+value.replace('"', '\\"')+'"'
			VarValueType.NUMBER,VarValueType.BOOL,VarValueType.EXPRESSION: # Float Bool, or Expression
				string += str(value)
			VarValueType.VARIABLE: # Variable
				string += '{'+value+'}'
			VarValueType.RANDOM_NUMBER:
				string += 'range('+str(random_min)+','+str(random_max)+').pick_random()'

	return string


func from_text(string:String) -> void:
	var reg := RegEx.new()
	reg.compile("set(?<name>[^=+\\-*\\/]*)?(?<operation>=|\\+=|-=|\\*=|\\/=)?(?<value>.*)")
	var result := reg.search(string)
	if !result:
		return
	name = result.get_string('name').strip_edges().replace("{", "").replace("}", "")
	match result.get_string('operation').strip_edges():
		'=':
			operation = Operations.SET
		'-=':
			operation = Operations.SUBSTRACT
		'+=':
			operation = Operations.ADD
		'*=':
			operation = Operations.MULTIPLY
		'/=':
			operation = Operations.DIVIDE

	_suppress_default_value = true
	value = result.get_string('value').strip_edges()
	if not value.is_empty():
		if value.begins_with('"') and value.ends_with('"') and value.count('"')-value.count('\\"') == 2:
			value = result.get_string('value').strip_edges().replace('"', '')
			_value_type = VarValueType.STRING
		elif value.begins_with('{') and value.ends_with('}') and value.count('{') == 1:
			value = result.get_string('value').strip_edges().trim_suffix('}').trim_prefix('{')
			_value_type = VarValueType.VARIABLE
		elif value in ["true", "false"]:
			value = value == "true"
			_value_type = VarValueType.BOOL
		elif value.begins_with('range(') and value.ends_with(').pick_random()'):
			_value_type = VarValueType.RANDOM_NUMBER
			var randinf := str(value).trim_prefix('range(').trim_suffix(').pick_random()').split(',')
			random_min = int(randinf[0])
			random_max = int(randinf[1])
		else:
			value = result.get_string('value').strip_edges()
			if value.is_valid_float():
				_value_type = VarValueType.NUMBER
			else:
				_value_type = VarValueType.EXPRESSION
	else:
		value = null
	_suppress_default_value = false


func is_valid_event(string:String) -> bool:
	return string.begins_with('set')


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('name', ValueType.DYNAMIC_OPTIONS, {
			'left_text'		: 'Set',
			'suggestions_func' 	: get_var_suggestions,
			'icon' 					: load("res://addons/dialogic/Editor/Images/Pieces/variable.svg"),
			'placeholder'			:'Select Variable'}
			)
	add_header_edit('operation', ValueType.FIXED_OPTIONS, {
		'options': [
			{
				'label': 'to be',
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/set.svg"),
				'value': Operations.SET
			},{
				'label': 'to itself plus',
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/plus.svg"),
				'value': Operations.ADD
			},{
				'label': 'to itself minus',
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/minus.svg"),
				'value': Operations.SUBSTRACT
			},{
				'label': 'to itself multiplied by',
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/multiply.svg"),
				'value': Operations.MULTIPLY
			},{
				'label': 'to itself divided by',
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/divide.svg"),
				'value': Operations.DIVIDE
			}
		]
	}, '!name.is_empty()')
	add_header_edit('_value_type', ValueType.FIXED_OPTIONS, {
		'options': [
			{
				'label': 'String',
				'icon': ["String", "EditorIcons"],
				'value': VarValueType.STRING
			},{
				'label': 'Number',
				'icon': ["float", "EditorIcons"],
				'value': VarValueType.NUMBER
			},{
				'label': 'Variable',
				'icon': load("res://addons/dialogic/Editor/Images/Pieces/variable.svg"),
				'value': VarValueType.VARIABLE
			},{
				'label': 'Bool',
				'icon': ["bool", "EditorIcons"],
				'value': VarValueType.BOOL
			},{
				'label': 'Expression',
				'icon': ["Variant", "EditorIcons"],
				'value': VarValueType.EXPRESSION
			},{
				'label': 'Random Number',
				'icon': ["RandomNumberGenerator", "EditorIcons"],
				'value': VarValueType.RANDOM_NUMBER
			}],
		'symbol_only':true},
		'!name.is_empty()')
	add_header_edit('value', ValueType.SINGLELINE_TEXT, {}, '!name.is_empty() and (_value_type == VarValueType.STRING or _value_type == VarValueType.EXPRESSION) ')
	add_header_edit('value', ValueType.BOOL, {}, '!name.is_empty() and (_value_type == VarValueType.BOOL) ')
	add_header_edit('value', ValueType.NUMBER, {}, '!name.is_empty()  and _value_type == VarValueType.NUMBER')
	add_header_edit('value', ValueType.DYNAMIC_OPTIONS,
			{'suggestions_func' : get_value_suggestions, 'placeholder':'Select Variable'},
			'!name.is_empty() and _value_type == VarValueType.VARIABLE')
	add_header_label('a number between', '_value_type == VarValueType.RANDOM_NUMBER')
	add_header_edit('random_min', ValueType.NUMBER, {'right_text':'and', 'mode':1}, '!name.is_empty() and  _value_type == VarValueType.RANDOM_NUMBER')
	add_header_edit('random_max', ValueType.NUMBER, {'mode':1}, '!name.is_empty() and _value_type == VarValueType.RANDOM_NUMBER')
	add_header_button('', _on_variable_editor_pressed, 'Variable Editor', ["ExternalLink", "EditorIcons"])


func get_var_suggestions(filter:String) -> Dictionary:
	var suggestions := {}
	if filter:
		suggestions[filter] = {'value':filter, 'editor_icon':["GuiScrollArrowRight", "EditorIcons"]}
	for var_path in DialogicUtil.list_variables(DialogicUtil.get_default_variables()):
		suggestions[var_path] = {'value':var_path, 'icon':load("res://addons/dialogic/Editor/Images/Pieces/variable.svg")}
	return suggestions


func get_value_suggestions(filter:String) -> Dictionary:
	var suggestions := {}

	for var_path in DialogicUtil.list_variables(DialogicUtil.get_default_variables()):
		suggestions[var_path] = {'value':var_path, 'icon':load("res://addons/dialogic/Editor/Images/Pieces/variable.svg")}
	return suggestions


func _on_variable_editor_pressed():
	var editor_manager := _editor_node.find_parent('EditorsManager')
	if editor_manager:
		editor_manager.open_editor(editor_manager.editors['VariablesEditor']['node'], true)


func update_editor_warning() -> void:
	if _value_type == VarValueType.STRING and operation != Operations.SET:
		ui_update_warning.emit('You cannot do this operation with a string!')
	elif operation != Operations.SET:
		var type := DialogicUtil.get_variable_type(name)
		if not type in [DialogicUtil.VarTypes.INT, DialogicUtil.VarTypes.FLOAT, DialogicUtil.VarTypes.ANY]:
			ui_update_warning.emit('The selected variable is not a number!')
		else:
			ui_update_warning.emit('')
	else:
		ui_update_warning.emit('')



####################### CODE COMPLETION ########################################
################################################################################

func _get_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit, line:String, word:String, symbol:String) -> void:
	if CodeCompletionHelper.get_line_untill_caret(line) == 'set ':
		TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, '{', '{', TextNode.syntax_highlighter.variable_color)
	if symbol == '{':
		CodeCompletionHelper.suggest_variables(TextNode)


func _get_start_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit) -> void:
	TextNode.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'set', 'set ', event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.5))


#################### SYNTAX HIGHLIGHTING #######################################
################################################################################

func _get_syntax_highlighting(Highlighter:SyntaxHighlighter, dict:Dictionary, line:String) -> Dictionary:
	dict[line.find('set')] = {"color":event_color.lerp(Highlighter.normal_color, 0.5)}
	dict[line.find('set')+3] = {"color":Highlighter.normal_color}
	dict = Highlighter.color_region(dict, Highlighter.string_color, line, '"', '"', line.find('set'))
	dict = Highlighter.color_region(dict, Highlighter.variable_color, line, '{', '}', line.find('set'))
	return dict
