@tool
class_name DialogicWaitInputEvent
extends DialogicEvent

## Event that waits for input before continuing.

################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	dialogic.Text.hide_text_boxes()
	dialogic.current_state = Dialogic.states.IDLE
	finish()

################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Wait for Input"
	set_default_color('Color6')
	event_category = "Other"
	event_sorting_index = 10
	expand_by_default = false
	continue_at_end = false


################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "wait_input"
