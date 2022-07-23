tool
extends DialogicEvent
class_name DialogicVariableEvent

enum OPERATIONS {SET, ADD, SUBSTRACT, MULTIPLY, DEVIDE}

# DEFINE ALL PROPERTIES OF THE EVENT
var Name: String = ""
var Operation: int = OPERATIONS.SET
var Value: String = ""

func _execute() -> void:
	if Name:
		var orig = dialogic.VAR.get_variable(Name)
		var value = dialogic.VAR.get_variable(Value, Value)
		if Operation != OPERATIONS.SET and orig.is_valid_float() and value.is_valid_float():
			orig = float(orig)
			value = float(value)
			match Operation:
				OPERATIONS.ADD:
					dialogic.VAR.set_variable(Name, str(orig+value))
				OPERATIONS.SUBSTRACT:
					dialogic.VAR.set_variable(Name, str(orig-value))
				OPERATIONS.MULTIPLY:
					dialogic.VAR.set_variable(Name, str(orig*value))
				OPERATIONS.DEVIDE:
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


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "variable"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"name"		: "Name",
		'operation' : "Operation",
		"value"		: "Value",
	}

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('Name', ValueType.ComplexPicker, '', '', {'suggestions_func':[self, 'get_var_suggestions'], 'editor_icon':["ClassList", "EditorIcons"]})
	add_header_edit('Operation', ValueType.FixedOptionSelector, '', '', {'selector_options':
		{'to be':OPERATIONS.SET, 'to itself plus':OPERATIONS.ADD, 'to itself minus':OPERATIONS.SUBSTRACT, 'to itself multiplied by':OPERATIONS.MULTIPLY, 'to itself divided by':OPERATIONS.DEVIDE}
		}, 'Name')
	add_header_edit('Value', ValueType.ComplexPicker, '', '', {'suggestions_func':[self, 'get_value_suggestions'], 'editor_icon':["Variant", "EditorIcons"]}, 'Name')

func get_var_suggestions(filter:String) -> Dictionary:
	var suggestions = {}
	
	if filter:
		suggestions[filter] = filter
	var vars = DialogicUtil.get_project_setting('dialogic/variables', {})
	for var_path in list_variables(vars):
		if !filter or filter.to_lower() in var_path.to_lower():
			suggestions[var_path] = var_path
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
		suggestions[filter] = filter
	var vars = DialogicUtil.get_project_setting('dialogic/variables', {})
	for var_path in list_variables(vars):
		if filter.to_lower() in var_path.to_lower():
			suggestions[var_path] = var_path
	return suggestions
