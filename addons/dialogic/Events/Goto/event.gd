tool
extends DialogicEvent
class_name DialogicGoToEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var LabelToGoTo :String = ""

func _execute() -> void:
	var idx = -1
	if LabelToGoTo:
		dialogic_game_handler.jump_to_label(LabelToGoTo)
	finish()

################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Go to"
	event_color = Color("#12b76a")
	event_category = Category.TIMELINE
	event_sorting_index = 2
	continue_at_end = true


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "go to"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"label"		: "LabelToGoTo",
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('LabelToGoTo', ValueType.SinglelineText, '')
