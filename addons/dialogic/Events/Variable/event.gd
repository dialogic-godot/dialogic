@tool
extends DialogicEvent
class_name DialogicVariableEvent

enum OPERATIONS {SET, ADD, SUBSTRACT, MULTIPLY, DIVIDE}

# DEFINE ALL PROPERTIES OF THE EVENT
var Name: String = ""
var Operation: int = OPERATIONS.SET
var Value: String = ""
var RandomEnabled :bool= false
var RandomMin :int = 0
var RandomMax :int = 100

func _execute() -> void:
	if Name:
		var orig = dialogic.VAR.get_variable(Name)
		var value = dialogic.VAR.get_variable(Value, Value)
		if RandomEnabled:
			value = randi()%(RandomMax-RandomMin)+RandomMin
		
		if orig != null:
			if Operation != OPERATIONS.SET and orig.is_valid_float() and value.is_valid_float():
				orig = orig.to_float()
				value = value.to_float()
				match Operation:
					OPERATIONS.ADD:
						dialogic.VAR.set_variable(Name, str(orig+value))
					OPERATIONS.SUBSTRACT:
						dialogic.VAR.set_variable(Name, str(orig-value))
					OPERATIONS.MULTIPLY:
						dialogic.VAR.set_variable(Name, str(orig*value))
					OPERATIONS.DIVIDE:
						dialogic.VAR.set_variable(Name, str(orig/value))
			else:
				dialogic.VAR.set_variable(Name, str(value))
	finish()


func get_required_subsystems() -> Array:
	return [
				{'name':'VAR',
				'subsystem': get_script().resource_path.get_base_dir().path_join('Subsystem_Variables.gd'),
				'settings': get_script().resource_path.get_base_dir().path_join('SettingsEditor/Editor.tscn'),
				},
			]


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Set Variable"
	set_default_color('Color1')
	event_category = Category.GODOT
	event_sorting_index = 0
	expand_by_default = false


################################################################################
## 						SAVING/LOADING
################################################################################
## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func to_text() -> String:
	var string = "VAR "
	if Name:
		string += "{" + Name + "}"
		match Operation:
			OPERATIONS.SET:
				string+= " = "
			OPERATIONS.ADD:
				string+= " += "
			OPERATIONS.SUBSTRACT:
				string+= " -= "
			OPERATIONS.MULTIPLY:
				string+= " *= "
			OPERATIONS.DIVIDE:
				string+= " /= "
		string += Value
	if RandomEnabled:
		string += ' [random="True"'
		if RandomMin != 0:
			string += ' min="'+str(RandomMin)+'"' 
		if RandomMax != 100:
			string += ' max="'+str(RandomMax)+'"' 
		string += "]"
	return string

## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func from_text(string:String) -> void:
	var reg = RegEx.new()
	reg.compile("VAR (?<name>[^=+\\-*\\/]*)(?<operation>=|\\+=|-=|\\*=|\\/=)(?<value>[^\\[\\n]*)(?<shortcode>\\[.*)?")
	var result = reg.search(string)
	Name = result.get_string('name').strip_edges().replace("{", "").replace("}", "")
	match result.get_string('operation').strip_edges():
		'=':
			Operation = OPERATIONS.SET
		'-=':
			Operation = OPERATIONS.SUBSTRACT
		'+=':
			Operation = OPERATIONS.ADD
		'*=':
			Operation = OPERATIONS.MULTIPLY
		'/=':
			Operation = OPERATIONS.DIVIDE
	Value = result.get_string('value').strip_edges()
	
	if !result.get_string('shortcode').is_empty():
		var shortcodeparams = parse_shortcode_parameters(result.get_string('shortcode'))
		RandomEnabled = true if shortcodeparams.get('random', "True") == "True" else false
		RandomMin = DialogicUtil.logical_convert(shortcodeparams.get('min', 0))
		RandomMax = DialogicUtil.logical_convert(shortcodeparams.get('max', 100))

func is_valid_event(string:String) -> bool:
	return string.begins_with('VAR ')

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('Name', ValueType.ComplexPicker, '', '', {'suggestions_func':get_var_suggestions, 'editor_icon':["ClassList", "EditorIcons"]})
	add_header_edit('Operation', ValueType.FixedOptionSelector, '', '', {
		'selector_options': [
			{
				'label': 'to be',
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/set.svg"),
				'value': OPERATIONS.SET
			},
			{
				'label': 'to itself plus',
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/plus.svg"),
				'value': OPERATIONS.ADD
			},
			{
				'label': 'to itself minus',
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/minus.svg"),
				'value': OPERATIONS.SUBSTRACT
			},
			{
				'label': 'to itself multiplied by',
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/multiply.svg"),
				'value': OPERATIONS.MULTIPLY
			},
			{
				'label': 'to itself divided by',
				'icon': load("res://addons/dialogic/Editor/Images/Dropdown/divide.svg"),
				'value': OPERATIONS.DIVIDE
			}
		]
	}, '!Name.is_empty()')
	add_header_edit('Value', ValueType.ComplexPicker, '', '', {'suggestions_func':get_value_suggestions, 'editor_icon':["Variant", "EditorIcons"], }, '!Name.is_empty() and not RandomEnabled')
	add_header_label('a random integer', 'RandomEnabled')
	add_body_edit('RandomEnabled', ValueType.Bool, 'Use Random Integer:', '', {}, '!Name.is_empty()')
	add_body_edit('RandomMin', ValueType.Integer, 'Min:', '', {}, '!Name.is_empty() and RandomEnabled')
	add_body_edit('RandomMax', ValueType.Integer, 'Max:', '', {}, '!Name.is_empty() and RandomEnabled')

func get_var_suggestions(filter:String) -> Dictionary:
	var suggestions = {}
	
	if filter:
		suggestions[filter] = {'value':filter, 'editor_icon':["GuiScrollArrowRight", "EditorIcons"]}
	var vars = DialogicUtil.get_project_setting('dialogic/variables', {})
	for var_path in list_variables(vars):
		suggestions[var_path] = {'value':var_path, 'editor_icon':["ClassList", "EditorIcons"]}
	return suggestions


func list_variables(dict, path = "") -> Array:
	var array = []
	for key in dict.keys():
		if typeof(dict[key]) == TYPE_DICTIONARY:
			array.append_array(list_variables(dict[key], path+key+"."))
		else:
			array.append(path+key)
	return array

func get_value_suggestions(filter:String) -> Dictionary:
	var suggestions = {}
	
	if filter:
		suggestions[filter] = {'value':filter, 'editor_icon':["GuiScrollArrowRight", "EditorIcons"]}
	var vars = DialogicUtil.get_project_setting('dialogic/variables', {})
	for var_path in list_variables(vars):
		suggestions[var_path] = {'value':var_path, 'editor_icon':["ClassList", "EditorIcons"]}
	return suggestions
