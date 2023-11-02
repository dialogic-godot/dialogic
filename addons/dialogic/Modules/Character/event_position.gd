@tool
class_name DialogicPositionEvent
extends DialogicEvent

## Event that allows moving of positions (and characters that are on that position).
## Requires the Portraits subsystem to be present!

enum Actions {SET_RELATIVE, SET_ABSOLUTE, RESET, RESET_ALL}


### Settings

## The type of action: SetRelative, SetAbsolute, Reset, ResetAll
var action := Actions.SET_RELATIVE
## The position that should be affected
var position: int = 0
## A vector representing a relative change or an absolute position (for SetRelative and SetAbsolute)
var vector: Vector2 = Vector2()
## The time the tweening will take.
var movement_time: float = 0


################################################################################
## 						EXECUTE
################################################################################
func _execute() -> void:
	var final_movement_time: float = movement_time

	if Dialogic.Input.auto_skip.enabled:
		var time_per_event: float = Dialogic.Input.auto_skip.time_per_event
		final_movement_time = max(movement_time, time_per_event)

	match action:
		Actions.SET_RELATIVE:
			dialogic.Portraits.move_portrait_position(position, vector, true, final_movement_time)
		Actions.SET_ABSOLUTE:
			dialogic.Portraits.move_portrait_position(position, vector, false, final_movement_time)
		Actions.RESET_ALL:
			dialogic.Portraits.reset_all_portrait_positions(final_movement_time)
		Actions.RESET:
			dialogic.Portraits.reset_portrait_position(position, final_movement_time)

	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Position"
	set_default_color('Color2')
	event_category = "Other"
	event_sorting_index = 2


func _get_icon() -> Resource:
	return load(self.get_script().get_path().get_base_dir().path_join('event_portrait_position.svg'))

################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "update_position"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		"action"		:  {"property": "action", 		"default": Actions.SET_RELATIVE,
								"suggestions": func(): return {"Set Relative":{'value':0, 'text_alt':['set_relative', 'relative']}, "Set Absolute":{'value':1, 'text_alt':['set_absolute', 'absolute']}, "Reset":{'value':2,'text_alt':['reset'] }, "Reset All":{'value':3,'text_alt':['reset_all']}}},
		"position"		:  {"property": "position", 		"default": 0},
		"vector"		:  {"property": "vector", 			"default": Vector2()},
		"time"			:  {"property": "movement_time", 	"default": 0},
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('action', ValueType.FIXED_OPTION_SELECTOR, {
		'selector_options': [
			{
				'label': 'Change',
				'value': Actions.SET_RELATIVE,
			},
			{
				'label': 'Set',
				'value': Actions.SET_ABSOLUTE,
			},
			{
				'label': 'Reset',
				'value': Actions.RESET,
			},
			{
				'label': 'Reset All',
				'value': Actions.RESET_ALL,
			}
		]
		})
	add_header_edit("position", ValueType.INTEGER, {'left_text':"position"},
			'action != Actions.RESET_ALL')
	add_header_label('to (absolute)', 'action == Actions.SET_ABSOLUTE')
	add_header_label('by (relative)', 'action == Actions.SET_RELATIVE')
	add_header_edit("vector", ValueType.VECTOR2, {},
			'action != Actions.RESET and action != Actions.RESET_ALL')
	add_body_edit("movement_time", ValueType.FLOAT, {'left_text':"AnimationTime:", "right_text":"(0 for instant)"})
