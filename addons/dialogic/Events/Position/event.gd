@tool
extends DialogicEvent
class_name DialogicPositionEvent

var Position: int = 1
var Destination_X: int = 0
var Destination_Y: int = 0
var RelativePosition: bool = false
var MovementTime: float = 0
var NewPosition: bool = false
var ResetAll: bool = false

#Requires the Portraits subsystem to be present

func _execute() -> void:
	# If for some someone sets it to 0, ignore it entirely. 0 position is used for Update to indicate no change.
	if Position > 0:
		if NewPosition:
			dialogic.Portraits.add_portrait_position(Position, Destination_X, Destination_Y)
		elif ResetAll: 
			dialogic.Portraits.reset_portrait_positions()
		else: 
			dialogic.Portraits.move_portrait_position(Position, Destination_X, Destination_Y, RelativePosition, MovementTime)


func get_required_subsystems() -> Array:
	return [
				{'name':'Portraits',
				'subsystem': get_script().resource_path.get_base_dir().plus_file('Subsystem_Portraits.gd'),
				},
			]

func _init() -> void:
	event_name = "Position"
	set_default_color('Color2')
	event_category = Category.MAIN
	event_sorting_index = 2
	continue_at_end = true
	expand_by_default = true
	
func build_event_editor():
	add_header_edit("Position", ValueType.Integer, "Position to move:")
	add_header_edit("Destination_X", ValueType.ScreenValue, "X: ")
	add_header_edit("Destination_Y", ValueType.ScreenValue, "Y: ")
	add_header_edit("RelativePosition", ValueType.Bool, "New position is relative?")
	add_body_edit("MovementTime", ValueType.Float, "Time for movement: ")
	add_body_edit("NewPosition", ValueType.Bool, "Is this a new position?")
	add_body_edit("ResetAll", ValueType.Bool, "Reset all positions?")

################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "update_position"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"number"		: "Position",
		"x"				: "Destination_X",
		"y"				: "Destination_Y",
		"new"			: "NewPosition",
		"relative"		: "RelativePosition",
		"time"			: "MovementTime",
		"reset"			: "ResetAll"
	}
