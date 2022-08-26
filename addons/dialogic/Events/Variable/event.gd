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
				'subsystem': get_script().resource_path.get_base_dir().plus_file('Subsystem_Variables.gd'),
				'settings': get_script().resource_path.get_base_dir().plus_file('SettingsEditor/Editor.tscn'),
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
func get_as_string_to_store() -> String:
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
func load_from_string_to_store(string:String):
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

func is_valid_event_string(string:String) -> bool:
	return string.begins_with('VAR ')

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('Name', ValueType.ComplexPicker, '', '', {'suggestions_func':[self, 'get_var_suggestions'], 'editor_icon':["ClassList", "EditorIcons"], 'disable_pretty_name':true})
	add_header_edit('Operation', ValueType.FixedOptionSelector, '', '', {'selector_options':
		{'to be':OPERATIONS.SET, 'to itself plus':OPERATIONS.ADD, 'to itself minus':OPERATIONS.SUBSTRACT, 'to itself multiplied by':OPERATIONS.MULTIPLY, 'to itself divided by':OPERATIONS.DIVIDE}
		}, '!Name.is_empty()')
	add_header_edit('Value', ValueType.ComplexPicker, '', '', {'suggestions_func':[self, 'get_value_suggestions'], 'editor_icon':["Variant", "EditorIcons"], 'disable_pretty_name':true}, '!Name.is_empty() and not RandomEnabled')
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
		if filter.is_empty() or filter.to_lower() in var_path.to_lower():
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
		if filter.is_empty() or filter.to_lower() in var_path.to_lower():
			suggestions[var_path] = {'value':var_path, 'editor_icon':["ClassList", "EditorIcons"]}
	return suggestions
