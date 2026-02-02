@tool
class_name DialogicWaitEvent
extends DialogicEvent

## Event that waits for some time before continuing.


### Settings

## The time in seconds that the event will stop before continuing.
@export var time: float = 1.0
## If true the text box will be hidden while the event waits.
@export var hide_text := true
## If true the wait can be skipped with user input
@export var skippable := false


#region EXECUTE
################################################################################

func _execute() -> void:
	await dialogic.Wait.update_wait(time, hide_text, skippable)

	if dialogic.Animations.is_animating():
		dialogic.Animations.stop_animation()
	dialogic.current_state = dialogic.States.IDLE

	finish()

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Wait"
	event_description = "Waits a given amount of time. Can hide the textbox and be skippable."
	set_default_color('Color5')
	event_category = "Flow"
	event_sorting_index = 11

#endregion


#region SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "wait"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_info
		"time" 		:  {"property": "time", 		"default": 1},
		"hide_text" :  {"property": "hide_text", 	"default": true},
		"skippable" :  {"property": "skippable", 	"default": false},
	}

#endregion


#region EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	add_header_edit('time', ValueType.NUMBER, {'left_text':'Wait', 'autofocus':true, 'min':0.1})
	add_header_label('seconds', 'time != 1')
	add_header_label('second', 'time == 1')
	add_body_edit('hide_text', ValueType.BOOL, {'left_text':'Hide text box:'})
	add_body_edit('skippable', ValueType.BOOL, {'left_text':'Skippable:'})

#endregion
