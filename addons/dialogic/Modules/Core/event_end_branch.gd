@tool
class_name DialogicEndBranchEvent
extends DialogicEvent

## Event that indicates the end of a condition or choice (or custom branch).
## In text this is not stored (only as a change in indentation).


#region EXECUTE
################################################################################

func _execute() -> void:
	dialogic.current_event_idx = find_next_index()-1
	finish()


## Returns the index of the first event that
## - is on the same "indentation"
## - is not a branching event (unless it is a branch starter)
func find_next_index() -> int:
	var idx: int = dialogic.current_event_idx
	while true:
		idx += 1
		var event: DialogicEvent = dialogic.current_timeline.get_event(idx)
		if not event:
			return idx

		if event.can_contain_events:
			if event._is_branch_starter():
				break
			else:
				idx = event.get_end_branch_index()
				break
		else:
			break

	return idx


func get_opening_index() -> int:
	var index: int = dialogic.current_timeline_events.find(self)
	while true:
		index -= 1
		if index < 0:
			break
		var event: DialogicEvent = dialogic.current_timeline_events[index]
		if event is DialogicEndBranchEvent:
			index = event.get_opening_index()
		elif event.can_contain_events:
			return index
	return 0

#endregion

#region INITIALIZE
################################################################################

func _init() -> void:
	event_name = "End Branch"
	disable_editor_button = true

#endregion

#region SAVING/LOADING
################################################################################

## NOTE: This event is very special. It is rarely stored at all, as it is usually
## just a placeholder for removing an indentation level.
## When copying events however, some representation of this is necessary. That's why this is half-implemented.
func to_text() -> String:
	return "<<END BRANCH>>"


func from_text(_string:String) -> void:
	pass


func is_valid_event(string:String) -> bool:
	if string.strip_edges().begins_with("<<END BRANCH>>"):
		return true
	return false
