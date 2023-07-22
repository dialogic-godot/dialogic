@tool
class_name DialogicVariableEvent
extends DialogicEvent

## Event that allows changing a dialogic variable or a property of an autoload.


enum Operations {Set, Add, Substract, Multiply, Divide}

## Settings

## Name/Path of the variable that should be changed.
var name: String = ""
## The operation to perform.
var operation: int = Operations.Set:
	set(value):
		operation = value
		if operation != Operations.Set and _value_type == 0:
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
			
			if operation != Operations.Set and str(orig).is_valid_float() and str(the_value).is_valid_float():
				orig = float(orig)
				the_value = float(the_value)
				match operation:
					Operations.Add:
						dialogic.VAR.set_variable(name, orig+the_value)
					Operations.Substract:
						dialogic.VAR.set_variable(name, orig-the_value)
					Operations.Multiply:
						dialogic.VAR.set_variable(name, orig*the_value)
					Operations.Divide:
						dialogic.VAR.set_variable(name, orig/the_value)
				dialogic.VAR.variable_was_set.emit({'variable':name, 'new_value':the_value, 'value':value})
			elif operation == Operations.Set:
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
	set_default_color('Color3')
	event_category = "Logic"
	event_sorting_index = 0
	expand_by_default = false


################################################################################
## 						SAVING/LOADING
################################################################################

func to_text() -> String:
	var string := "VAR "
	if name:
		string += "{" + name + "}"
		match operation:
			Operations.Set:
				string+= " = "
			Operations.Add:
				string+= " += "
			Operations.Substract:
				string+= " -= "
			Operations.Multiply:
				string+= " *= "
			Operations.Divide:
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
	reg.compile("VAR(?<name>[^=+\\-*\\/]*)?(?<operation>=|\\+=|-=|\\*=|\\/=)?(?<value>.*)")
	var result := reg.search(string)
	if !result:
		return
	name = result.get_string('name').strip_edges().replace("{", "").replace("}", "")
	match result.get_string('operation').strip_edges():
		'=':
			operation = Operations.Set
		'-=':
			operation = Operations.Substract
		'+=':
			operation = Operations.Add
		'*=':
			operation = Operations.Multiply
		'/=':
			operation = Operations.Divide
	
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
	return string.begins_with('VAR')


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('name', ValueType.ComplexPicker, '', '', 
			{'suggestions_func' 	: get_var_suggestions, 
			'editor_icon' 			: ["ClassList", "EditorIcons"],
			'placeholder'			:'Select Variable'}
			)
	add_header_edit('operation', ValueType.FixedOptionSelector, '', '', {
		'selector_options': [
			{
				'label': 'to be',
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/set.svg"),
				'value': Operations.Set
			},{
				'label': 'to itself plus',
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/plus.svg"),
				'value': Operations.Add
			},{
				'label': 'to itself minus',
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/minus.svg"),
				'value': Operations.Substract
			},{
				'label': 'to itself multiplied by',
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/multiply.svg"),
				'value': Operations.Multiply
			},{
				'label': 'to itself divided by',
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/divide.svg"),
				'value': Operations.Divide
			}
		]
	}, '!name.is_empty()')
	add_header_edit('_value_type', ValueType.FixedOptionSelector, '', '', {
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
			},{
				'label': 'Random Number',
				'icon': ["RandomNumberGenerator", "EditorIcons"],
				'value': 4
			}],
		'symbol_only':true}, 
		'!name.is_empty()')
	add_header_edit('value', ValueType.SinglelineText, '', '', {}, '!name.is_empty() and (_value_type == 0 or _value_type == 3) ')
	add_header_edit('value', ValueType.Float, '', '', {}, '!name.is_empty()  and _value_type == 1')
	add_header_edit('value', ValueType.ComplexPicker, '', '', 
			{'suggestions_func' : get_value_suggestions, 'placeholder':'Select Variable'}, 
			'!name.is_empty() and _value_type == 2')
	add_header_label('a number between', '_value_type == 4')
	add_header_edit('random_min', ValueType.Integer, '', 'and', {}, '!name.is_empty() and  _value_type == 4')
	add_header_edit('random_max', ValueType.Integer, '', '', {}, '!name.is_empty() and _value_type == 4')
	add_header_button('', _on_variable_editor_pressed, 'Variable Editor', ["ExternalLink", "EditorIcons"])

func get_var_suggestions(filter:String) -> Dictionary:
	var suggestions := {}
	
	if filter:
		suggestions[filter] = {'value':filter, 'editor_icon':["GuiScrollArrowRight", "EditorIcons"]}
	var vars: Dictionary = ProjectSettings.get_setting('dialogic/variables', {})
	for var_path in DialogicUtil.list_variables(vars):
		suggestions[var_path] = {'value':var_path, 'editor_icon':["ClassList", "EditorIcons"]}
	return suggestions


func get_value_suggestions(filter:String) -> Dictionary:
	var suggestions := {}
	
	var vars: Dictionary = ProjectSettings.get_setting('dialogic/variables', {})
	for var_path in DialogicUtil.list_variables(vars):
		suggestions[var_path] = {'value':var_path, 'editor_icon':["ClassList", "EditorIcons"]}
	return suggestions


func _on_variable_editor_pressed():
	var editor_manager := _editor_node.find_parent('EditorsManager')
	if editor_manager:
		editor_manager.open_editor(editor_manager.editors['VariablesEditor']['node'], true)


func update_editor_warning() -> void:
	if _value_type == 0 and operation != Operations.Set:
		ui_update_warning.emit('You cannot do this operation with a string!')
	else:
		ui_update_warning.emit('')
