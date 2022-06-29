tool
extends DialogicEvent
class_name DialogicChangeTimelineEvent

enum ReturnTypes {None, ReturnToLastPoint, ReturnPoint}

# DEFINE ALL PROPERTIES OF THE EVENT
var Timeline :DialogicTimeline = null
var Label : String = ""
var Return:int = ReturnTypes.None

func _execute() -> void:
	if Return == ReturnTypes.ReturnToLastPoint:
		if len(dialogic_game_handler.get_current_state_info('jump_returns', [])):
			var return_to = dialogic_game_handler.get_current_state_info('jump_returns', []).pop_back()
			dialogic_game_handler.start_timeline(return_to[0], return_to[1])
			return

	elif Return == ReturnTypes.ReturnPoint:
		var return_points = dialogic_game_handler.get_current_state_info('jump_returns', [])
		return_points.append(
			[dialogic_game_handler.current_timeline,
			dialogic_game_handler.current_event_idx+1]
			)
		dialogic_game_handler.set_current_state_info('jump_returns', return_points)

	if Timeline and Timeline != dialogic_game_handler.current_timeline:
		dialogic_game_handler.start_timeline(Timeline, Label)
	elif Label:
		dialogic_game_handler.jump_to_label(Label)
	else:
		finish()


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Jump"
	event_color = Color("#12b76a")
	event_category = Category.TIMELINE
	event_sorting_index = 0
	


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "jump"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"timeline"	: "Timeline",
		"label"		: "Label",
		"return"	: "Return",
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('Timeline', ValueType.Timeline, 'Timeline:')
	add_header_edit('Label', ValueType.SinglelineText, 'Label:')
	add_body_edit('Return', ValueType.FixedOptionSelector, 'Return mode:', '', {'selector_options':{"Nothing":ReturnTypes.None, "This is a return point":ReturnTypes.ReturnPoint, "Return to last return point":ReturnTypes.ReturnToLastPoint}})
