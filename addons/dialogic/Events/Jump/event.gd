tool
extends DialogicEvent
class_name DialogicChangeTimelineEvent

enum CheckpointModes {None, GoToCheckpoint, IsCheckpoint}

# DEFINE ALL PROPERTIES OF THE EVENT
var Timeline :DialogicTimeline = null
var Label : String = ""
var Checkpoint:int = CheckpointModes.None

func _execute() -> void:
	if Checkpoint == CheckpointModes.GoToCheckpoint:
		if len(dialogic_game_handler.get_current_state_info('checkpoints', [])):
			var checkpoint = dialogic_game_handler.get_current_state_info('checkpoints', []).pop_back()
			dialogic_game_handler.start_timeline(checkpoint[0], checkpoint[1])
			return
		else:
			printerr('[Dialogic] Tried jumping to checkpoint, but non registerd.')
			finish()
			return 

	elif Checkpoint == CheckpointModes.IsCheckpoint:
		var checkpoints = dialogic_game_handler.get_current_state_info('checkpoints', [])
		checkpoints.append(
			[dialogic_game_handler.current_timeline,
			dialogic_game_handler.current_event_idx+1]
			)
		dialogic_game_handler.set_current_state_info('checkpoints', checkpoints)

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
		"checkpoint": "Checkpoint",
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('Timeline', ValueType.Timeline, 'Timeline:')
	add_header_edit('Label', ValueType.SinglelineText, 'Label:')
	add_body_edit('Checkpoint', ValueType.FixedOptionSelector, 'Checkpoint mode:', '', {'selector_options':{"Nothing":CheckpointModes.None, "This is a checkpoint":CheckpointModes.IsCheckpoint, "Go to last checkpoint":CheckpointModes.GoToCheckpoint}})
