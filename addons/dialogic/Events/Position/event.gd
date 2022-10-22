@tool
extends DialogicEvent
class_name DialogicPositionEvent

enum ActionTypes {SetRelative, SetAbsolute, Reset, ResetAll}

var ActionType := ActionTypes.SetRelative
var Position: int = 1
var Vector: Vector2 = Vector2()
var MovementTime: float = 0

#Requires the Portraits subsystem to be present

func _execute() -> void:
	# If for some someone sets it to 0, ignore it entirely. 0 position is used for Update to indicate no change.
	if ActionType != ActionTypes.ResetAll and Position == 0:
		finish()
		return
	
	match ActionType:
		ActionTypes.SetRelative:
			dialogic.Portraits.move_portrait_position(Position, Vector, true, MovementTime)
		ActionTypes.SetAbsolute:
			dialogic.Portraits.move_portrait_position(Position, Vector, false, MovementTime)
		ActionTypes.ResetAll:
			dialogic.Portraits.reset_portrait_positions(MovementTime)
		ActionTypes.Reset:
			dialogic.Portraits.reset_portrait_position(Position, MovementTime)
	
	finish()


func get_required_subsystems() -> Array:
	return [
				{'name':'Portraits',
				'subsystem': get_script().resource_path.get_base_dir().path_join('Subsystem_Portraits.gd'),
				},
			]

func _init() -> void:
	event_name = "Position"
	set_default_color('Color2')
	event_category = Category.MAIN
	event_sorting_index = 2
	continue_at_end = true
	expand_by_default = false
	
func build_event_editor():
	add_header_edit('ActionType', ValueType.FixedOptionSelector, '', '', {
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
	add_header_edit("Position", ValueType.Integer, "position", '', {}, 'ActionType != ActionTypes.ResetAll')
	add_header_label('to (absolute)', 'ActionType == ActionTypes.SetAbsolute')
	add_header_label('by (relative)', 'ActionType == ActionTypes.SetRelative')
	add_header_edit("Vector", ValueType.Vector2, "", '', {}, 'ActionType != ActionTypes.Reset and ActionType != ActionTypes.ResetAll')
	add_body_edit("MovementTime", ValueType.Float, "AnimationTime:", "(0 for instant)")

################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "update_position"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_name
		"mode"			: "ActionType",
		"position"		: "Position",
		"vector"		: "Vector",
		"time"			: "MovementTime",
	}
