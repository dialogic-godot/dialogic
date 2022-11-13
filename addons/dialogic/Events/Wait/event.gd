@tool
class_name DialogicWaitEvent
extends DialogicEvent

## Event that waits for some time before continuing.


### Settings

## The time in seconds that the event will stop before continuing.
var time: float = 1.0
## If true the text box will be hidden while the event waits.
var hide_text: bool = true


################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	if hide_text and dialogic.has_subsystem("Text"):
		dialogic.Text.hide_text_boxes()
	dialogic.current_state = dialogic.states.WAITING
	await dialogic.get_tree().create_timer(time, true, DialogicUtil.is_physics_timer()).timeout
	dialogic.current_state = dialogic.states.IDLE
	if hide_text and dialogic.has_subsystem("Text"):
		dialogic.Text.show_text_boxes()
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Wait"
	set_default_color('Color6')
	event_category = Category.Timeline
	event_sorting_index = 5
	expand_by_default = false


################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "wait"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_info
		"time" 		:  {"property": "time", 		"default": 1},
		"hide_text" :  {"property": "hide_text", 	"default": true},
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('time', ValueType.Float)
	add_header_label('seconds.')
	add_body_edit('hide_text', ValueType.Bool, 'Hide text box:')
