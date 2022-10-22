@tool
extends DialogicEvent
class_name DialogicWaitEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var SecondsTime :float = 1.0
var HideText: bool = true

func _execute() -> void:
	if (HideText):
		dialogic.Text.hide_text_boxes()
	dialogic.current_state = dialogic.states.WAITING
	await dialogic.get_tree().create_timer(SecondsTime, true, DialogicUtil.is_physics_timer()).timeout
	dialogic.current_state = dialogic.states.IDLE
	if (HideText):
		dialogic.Text.show_text_boxes()
	finish()

################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Wait"
	set_default_color('Color6')
	event_category = Category.TIMELINE
	event_sorting_index = 5
	expand_by_default = false


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "wait"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"time"		: "SecondsTime",
		"hide_text"	: "HideText"
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('SecondsTime', ValueType.Float)
	add_header_label('seconds.')
	add_body_edit('HideText', ValueType.Bool, 'Hide text box:')
