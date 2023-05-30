@tool
class_name DialogicWaitInputEvent
extends DialogicEvent

## Event that waits for input before continuing.

var hide_textbox := true

################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	if hide_textbox: dialogic.Text.hide_text_boxes()
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

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_info
		"hide_text" :  {"property": "hide_textbox", 	"default": true, 
						"suggestions": func(): return {'True':{'value':'true'}, 'False':{'value':'false'}}},
	}


func build_event_editor():
	add_body_edit('hide_textbox', ValueType.Bool, 'Hide text box:')
