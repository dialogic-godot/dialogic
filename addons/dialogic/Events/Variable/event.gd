tool
extends DialogicEvent
class_name DialogicVariableEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var Name: String = ""
var Value: String = ""

func _execute() -> void:
	dialogic.VAR.set_variable(Name, Value)
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
		"value"		: "Value",
	}

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('Name', ValueType.SinglelineText, 'Name:')
	add_header_edit('Value', ValueType.SinglelineText, 'Value:')
