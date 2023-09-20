@tool
class_name DialogicVariableEvent
extends DialogicEvent

## Event that allows changing a dialogic variable or a property of an autoload.


enum Operations {SET, ADD, SUBSTRACT, MULTIPLY, DIVIDE}

## Settings

## Name/Path of the variable that should be changed.
var name: String = ""
## The operation to perform.
var operation: int = Operations.SET:
	set(value):
		operation = value
		if operation != Operations.SET and _value_type == 0:
			_value_type = 1
			ui_update_needed.emit()
		update_editor_warning()

## The value that is used. Can be a variable as well.
var value: Variant = ""
var _value_type := 0 :# helper for the ui 0 = string, 1= float, 2= variable 3= expression, 4= random int (a special expression)
	set(value):
		_value_type = value
		update_editor_warning()

## If true, a random number between [random_min] and [random_max] is used instead of [value].
var random_min: int = 0
var random_max: int = 100


################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	if name:
		var orig :Variant= dialogic.VAR.get_variable(name)
		if value and orig != null:
			var the_value :Variant
			match _value_type:
				0: the_value = dialogic.VAR.get_variable('"'+value+'"')
				2: the_value = dialogic.VAR.get_variable('{'+value+'}')
				1,3,4: the_value = dialogic.VAR.get_variable(value)
			
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
			0: # String
				string += '"'+value.replace('"', '\\"')+'"'
			1,3: # Float or Expression
				string += str(value)
			2: # Variable
				string += '{'+value+'}'
			4:
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
	
	if result.get_string('value'):
		value = result.get_string('value').strip_edges()
		if value.begins_with('"') and value.ends_with('"') and value.count('"')-value.count('\\"') == 2:
			value = result.get_string('value').strip_edges().replace('"', '')
			_value_type = 0
		elif value.begins_with('{') and value.ends_with('}') and value.count('{') == 1:
			value = result.get_string('value').strip_edges().trim_suffix('}').trim_prefix('{')
			_value_type = 2
		elif value.begins_with('range(') and value.ends_with(').pick_random()'):
			_value_type = 4
			var randinf := str(value).trim_prefix('range(').trim_suffix(').pick_random()').split(',')
			random_min = int(randinf[0])
			random_max = int(randinf[1])
		else:
			value = result.get_string('value').strip_edges()
			if value.is_valid_float():
				_value_type = 1
			else:
				_value_type = 3



func is_valid_event(string:String) -> bool:
	return string.begins_with('set')


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('name', ValueType.COMPLEX_PICKER, {
			'left_text'		: 'Set',  
			'suggestions_func' 	: get_var_suggestions, 
			'icon' 					: load("res://addons/dialogic/Editor/Images/Pieces/variable.svg"),
			'placeholder'			:'Select Variable'}
			)
	add_header_edit('operation', ValueType.FIXED_OPTION_SELECTOR, {
		'selector_options': [
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
	add_header_edit('_value_type', ValueType.FIXED_OPTION_SELECTOR, {
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
				'icon': load("res://addons/dialogic/Editor/Images/Pieces/variable.svg"),
				'value': 2
			},{
				'label': 'Expression',
				'icon': ["Variant", "EditorIcons"],
				'value': 3
			},{
				'label': 'Random Number',
				'icon': ["RandomNumberGenerator", "EditorIcons"],
				'value': 4
			}],
		'symbol_only':true}, 
		'!name.is_empty()')
	add_header_edit('value', ValueType.SINGLELINE_TEXT, {}, '!name.is_empty() and (_value_type == 0 or _value_type == 3) ')
	add_header_edit('value', ValueType.FLOAT, {}, '!name.is_empty()  and _value_type == 1')
	add_header_edit('value', ValueType.COMPLEX_PICKER, 
			{'suggestions_func' : get_value_suggestions, 'placeholder':'Select Variable'}, 
			'!name.is_empty() and _value_type == 2')
	add_header_label('a number between', '_value_type == 4')
	add_header_edit('random_min', ValueType.INTEGER, {'right_text':'and'}, '!name.is_empty() and  _value_type == 4')
	add_header_edit('random_max', ValueType.INTEGER, {}, '!name.is_empty() and _value_type == 4')
	add_header_button('', _on_variable_editor_pressed, 'Variable Editor', ["ExternalLink", "EditorIcons"])


func get_var_suggestions(filter:String) -> Dictionary:
	var suggestions := {}
	
	if filter:
		suggestions[filter] = {'value':filter, 'editor_icon':["GuiScrollArrowRight", "EditorIcons"]}
	var vars: Dictionary = ProjectSettings.get_setting('dialogic/variables', {})
	for var_path in DialogicUtil.list_variables(vars):
		suggestions[var_path] = {'value':var_path, 'icon':load("res://addons/dialogic/Editor/Images/Pieces/variable.svg")}
	return suggestions


func get_value_suggestions(filter:String) -> Dictionary:
	var suggestions := {}
	
	var vars: Dictionary = ProjectSettings.get_setting('dialogic/variables', {})
	for var_path in DialogicUtil.list_variables(vars):
		suggestions[var_path] = {'value':var_path, 'icon':load("res://addons/dialogic/Editor/Images/Pieces/variable.svg")}
	return suggestions


func _on_variable_editor_pressed():
	var editor_manager := _editor_node.find_parent('EditorsManager')
	if editor_manager:
		editor_manager.open_editor(editor_manager.editors['VariablesEditor']['node'], true)


func update_editor_warning() -> void:
	if _value_type == 0 and operation != Operations.SET:
		ui_update_warning.emit('You cannot do this operation with a string!')
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
