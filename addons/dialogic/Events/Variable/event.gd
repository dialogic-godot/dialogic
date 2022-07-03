tool
extends DialogicEvent
class_name DialogicVariableEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var Name: String = ""
var Value: String = ""

func _execute() -> void:
	#print('FROM EVENT: ', Name, Value)
	dialogic.set_variable(Name, Value)
	finish()


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Set Variable"
	event_color = Color("#0ca5eb")
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
