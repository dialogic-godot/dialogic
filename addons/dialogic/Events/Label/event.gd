@tool
extends DialogicEvent
class_name DialogicLabelEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var Name :String = ""

func _execute() -> void:
	finish()

################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Label"
	set_default_color('Color2')
	event_category = Category.TIMELINE
	event_sorting_index = 1
	continue_at_end = true


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "label"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"name"		: "Name",
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('Name', ValueType.SinglelineText, '')
