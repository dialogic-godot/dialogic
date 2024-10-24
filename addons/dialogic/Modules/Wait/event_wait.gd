@tool
class_name DialogicWaitEvent
extends DialogicEvent

## Event that waits for some time before continuing.


### Settings

## The time in seconds that the event will stop before continuing.
var time: float = 1.0
## If true the text box will be hidden while the event waits.
var hide_text := true
## If true the wait can be skipped with user input
var skippable := false

var _tween: Tween

################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	var final_wait_time := time

	if dialogic.Inputs.auto_skip.enabled:
		var time_per_event: float = dialogic.Inputs.auto_skip.time_per_event
		final_wait_time = min(time, time_per_event)

	dialogic.current_state = dialogic.States.WAITING

	if hide_text and dialogic.has_subsystem("Text"):
		dialogic.Text.update_dialog_text('', true)
		dialogic.Text.hide_textbox()

	_tween = dialogic.get_tree().create_tween()
	if DialogicUtil.is_physics_timer():
		_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_callback(_on_finish).set_delay(final_wait_time)
	
	if skippable:
		dialogic.Inputs.dialogic_action.connect(_on_finish)


func _on_finish() -> void:
	if is_instance_valid(_tween):
		_tween.kill()
	
	if skippable:
		dialogic.Inputs.dialogic_action.disconnect(_on_finish)
	
	if dialogic.Animations.is_animating():
		dialogic.Animations.stop_animation()
	dialogic.current_state = dialogic.States.IDLE

	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Wait"
	set_default_color('Color5')
	event_category = "Flow"
	event_sorting_index = 11


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
		"skippable" :  {"property": "skippable", 	"default": false},
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	add_header_edit('time', ValueType.NUMBER, {'left_text':'Wait', 'autofocus':true, 'min':0.1})
	add_header_label('seconds', 'time != 1')
	add_header_label('second', 'time == 1')
	add_body_edit('hide_text', ValueType.BOOL, {'left_text':'Hide text box:'})
	add_body_edit('skippable', ValueType.BOOL, {'left_text':'Skippable:'})
