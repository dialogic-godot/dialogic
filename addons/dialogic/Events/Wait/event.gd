tool
extends DialogicEvent
class_name DialogicWaitEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var SecondsTime :float = 1.0

func _execute() -> void:
	dialogic_game_handler.current_state = dialogic_game_handler.states.WAITING
	yield(dialogic_game_handler.get_tree().create_timer(SecondsTime), "timeout")
	dialogic_game_handler.current_state = dialogic_game_handler.states.IDLE
	finish()

################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Wait"
	event_color = Color("#657084")
	event_category = Category.TIMELINE
	event_sorting_index = 5


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "wait"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"time"		: "SecondsTime",
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('SecondsTime', ValueType.Float, 'Wait ')
	add_header_label('seconds.')
