extends DialogicSubsystem

## Subsystem that holds methods for jumping to specific labels, or return to the previous jump.

signal switched_timeline(info:Dictionary)
signal jumped_to_label(info:Dictionary)
signal returned_from_jump(info:Dictionary)

####################################################################################################
##					STATE
####################################################################################################

func clear_game_state(clear_flag:=Dialogic.ClearFlags.FULL_CLEAR):
	dialogic.current_state_info['jump_stack'] = []


func load_game_state():
	if not 'jump_stack' in dialogic.current_state_info:
		dialogic.current_state_info['jump_stack'] = []


####################################################################################################
##					MAIN METHODS
####################################################################################################

func jump_to_label(label:String) -> void:
	if label.is_empty():
		dialogic.current_event_idx = 0
		return
	var idx: int = -1
	while true:
		idx += 1
		var event: Variant = dialogic.current_timeline.get_event(idx)
		if not event:
			idx = dialogic.current_event_idx
			break
		if event is DialogicLabelEvent and event.name == label:
			break
	dialogic.current_event_idx = idx
	jumped_to_label.emit({'timeline':dialogic.current_timeline, 'label':label})


func push_to_jump_stack() -> void:
	dialogic.current_state_info['jump_stack'].push_back({'timeline':dialogic.current_timeline, 'index':dialogic.current_event_idx})


func resume_from_last_jump() -> void:
	var sub_timeline : DialogicTimeline = dialogic.current_timeline
	dialogic.start_timeline(
		dialogic.current_state_info['jump_stack'][-1].timeline, 
		dialogic.current_state_info['jump_stack'][-1].index+1)
	dialogic.current_state_info['jump_stack'].pop_back()
	returned_from_jump.emit({'sub_timeline':sub_timeline, 'label':dialogic.current_timeline.get_event(dialogic.current_event_idx-1).label_name})


func is_jump_stack_empty():
	return len(dialogic.current_state_info['jump_stack']) < 1
