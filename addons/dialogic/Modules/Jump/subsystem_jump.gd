extends DialogicSubsystem

## Subsystem that holds methods for jumping to specific labels, or return to the previous jump.


@warning_ignore("unused_signal") # this is emitted from the jump event
## Emitted when a jump event switches from one timeline to another. Gives a dictionary witht the keys:
## [br]
## Key                  | Value Type              | Value [br]
## -------------------- | ----------------------- | ----- [br]
## `previous_timeline`  | [type DialogicTimeline] | The timeline that we were in previously. [br]
## `timeline`           | [type DialogicTimeline] | The timeline we are in now. [br]
## `label`              | [type String]           | The label we went to (empty if beginning). [br]
signal switched_timeline(info:Dictionary)

## Emitted when a jump event jumps to a label. Gives a dictionary witht the keys:
## [br]
## Key         | Value Type              | Value [br]
## ----------- | ----------------------- | ----- [br]
## `timeline`  | [type DialogicTimeline] | The timeline we are in now. [br]
## `label`     | [type String]           | The label we went to (empty if beginning). [br]
signal jumped_to_label(info:Dictionary)

## Emitted when a return event is hit and there was a timeline to return to. Gives a dictionary witht the keys:
## [br]
## Key             | Value Type              | Value [br]
## --------------- | ----------------------- | ----- [br]
## `sub_timeline`  | [type DialogicTimeline] | The timeline we were in before. [br]
## `label`         | [type String]           | The label we went back to (empty if beginning). [br]
signal returned_from_jump(info:Dictionary)

## Emitted when a label event is executed (usually does nothing else). Gives a dictionary witht the keys:
## [br]
## Key                 | Value Type              | Value [br]
## ------------------- | ----------------------- | ----- [br]
## `identifier`        | [type String]           | The identifier of the label event. [br]
## `display_name`      | [type String]           | The display name, possibly translated. [br]
## `display_name_orig` | [type String]           | The untranslated display name. [br]
## `timeline`          | [type String]           | The identifier of the timeline we are in. [br]
signal passed_label(info:Dictionary)

#region STATE
####################################################################################################

func clear_game_state(_clear_flag:=DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	dialogic.current_state_info['jump_stack'] = []
	dialogic.current_state_info.erase("last_label")


func load_game_state(_load_flag:=LoadFlags.FULL_LOAD) -> void:
	if not 'jump_stack' in dialogic.current_state_info:
		dialogic.current_state_info['jump_stack'] = []

#endregion


#region MAIN METHODS JUMP
####################################################################################################

func jump_to_label(label:String) -> void:
	if label.is_empty():
		dialogic.current_event_idx = 0
		jumped_to_label.emit({'timeline':dialogic.current_timeline, 'label':""})
		return
	## Allows label to be a variable, making the jump event dynamic
	label = str(dialogic.VAR.parse_variables(label))

	var idx: int = -1
	while true:
		idx += 1
		var event: Variant = dialogic.current_timeline.get_event(idx)
		if not event:
			idx = dialogic.current_event_idx
			break
		if event is DialogicLabelEvent and event.name == label:
			break
	dialogic.current_event_idx = idx-1
	jumped_to_label.emit({'timeline':dialogic.current_timeline, 'label':label})


func push_to_jump_stack() -> void:
	dialogic.current_state_info['jump_stack'].push_back({'timeline':dialogic.current_timeline, 'index':dialogic.current_event_idx, 'label':dialogic.current_timeline_events[dialogic.current_event_idx].label_name})


func resume_from_last_jump() -> void:
	var sub_timeline: DialogicTimeline = dialogic.current_timeline
	var stack_info: Dictionary = dialogic.current_state_info['jump_stack'].pop_back()
	dialogic.start_timeline(stack_info.timeline, stack_info.index+1)
	returned_from_jump.emit({'sub_timeline':sub_timeline, 'label':stack_info.label})


func is_jump_stack_empty() -> bool:
	return len(dialogic.current_state_info['jump_stack']) < 1

#endregion


#region MAIN MEHTODS LABELS
####################################################################################################

func _ready() -> void:
	passed_label.connect(_on_passed_label)


func _on_passed_label(info:Dictionary) -> void:
	dialogic.current_state_info["last_label"] = info


## Returns the identifier name of the last passed label
func get_last_label_identifier() -> String:
	if not dialogic.current_state_info.has("last_label"):
		return ""

	return dialogic.current_state_info["last_label"].identifier


## Returns the display name of the last passed label (translated if translation are enabled)
func get_last_label_name() -> String:
	if not dialogic.current_state_info.has("last_label"):
		return ""

	return dialogic.current_state_info["last_label"].display_name
#endregion
