@tool
class_name DialogicPositionEvent
extends DialogicEvent

## Event that allows moving of positions (and characters that are on that position).
## Requires the Portraits subsystem to be present!

enum ActionTypes {SetRelative, SetAbsolute, Reset, ResetAll}


### Settings

## The type of action: SetRelative, SetAbsolute, Reset, ResetAll
var action_type := ActionTypes.SetRelative
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
	match action_type:
		ActionTypes.SetRelative:
			dialogic.Portraits.move_portrait_position(position, vector, true, movement_time)
		ActionTypes.SetAbsolute:
			dialogic.Portraits.move_portrait_position(position, vector, false, movement_time)
		ActionTypes.ResetAll:
			dialogic.Portraits.reset_portrait_positions(movement_time)
		ActionTypes.Reset:
			dialogic.Portraits.reset_portrait_position(position, movement_time)
	
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Position"
	set_default_color('Color2')
	event_category = Category.Other
	event_sorting_index = 2
	continue_at_end = true
	expand_by_default = false


func _get_icon() -> Resource:
	return load(self.get_script().get_path().get_base_dir().path_join('icon_position.png'))

################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "update_position"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		"action"		:  {"property": "action_type", 		"default": ActionTypes.SetRelative, 
								"suggestions": func(): return {"Set Relative":{'value':'0'}, "Set Absolute":{'value':'1'}, "Reset":{'value':'2'}, "Reset All":{'value':'3'}}},
		"position"		:  {"property": "position", 		"default": 0},
		"vector"		:  {"property": "vector", 			"default": Vector2()},
		"time"			:  {"property": "movement_time", 	"default": 0},
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('action_type', ValueType.FixedOptionSelector, '', '', {
		'selector_options': [
			{
				'label': 'Change',
				'value': ActionTypes.SetRelative,
			},
			{
				'label': 'Set',
				'value': ActionTypes.SetAbsolute,
			},
			{
				'label': 'Reset',
				'value': ActionTypes.Reset,
			},
			{
				'label': 'Reset All',
				'value': ActionTypes.ResetAll,
			}
		]
		})
	add_header_edit("position", ValueType.Integer, "position", '', {}, 
			'action_type != ActionTypes.ResetAll')
	add_header_label('to (absolute)', 'action_type == ActionTypes.SetAbsolute')
	add_header_label('by (relative)', 'action_type == ActionTypes.SetRelative')
	add_header_edit("vector", ValueType.Vector2, "", '', {}, 
			'action_type != ActionTypes.Reset and action_type != ActionTypes.ResetAll')
	add_body_edit("movement_time", ValueType.Float, "AnimationTime:", "(0 for instant)")
