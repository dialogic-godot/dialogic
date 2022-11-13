@tool
class_name DialogicEndBranchEvent
extends DialogicEvent

## Event that indicates the end of a condition or choice (or custom branch).
## In text this is not stored (only as a change in indentation). 


################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	dialogic.current_event_idx = find_next_index()-1
	finish()


func find_next_index():
	var idx: int = dialogic.current_event_idx
	
	var ignore: int = 1
	while true:
		idx += 1
		var event = dialogic.current_timeline.get_event(idx)
		if not event:
			return idx
		if event is DialogicEndBranchEvent:
			if ignore > 1: ignore -= 1
		elif event.can_contain_events and not event.should_execute_this_branch():
			ignore += 1
		elif ignore <= 1:
			return idx

	return idx


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "End Branch"
	event_color = Color(1,1,1,1)
	event_category = Category.Logic
	event_sorting_index = 0
	disable_editor_button = true
	continue_at_end = true


################################################################################
## 						SAVING/LOADING
################################################################################

## NOTE: This event is very special. It is rarely stored at all, as it is usually 
## just a placeholder for removing an indentation level.
## When copying events however, some representation of this is necessary. That's why this is half-implemented. 
func to_text() -> String:
	return "<<END BRANCH>>"


func from_text(string:String) -> void:
	pass


func is_valid_event(string:String) -> bool:
	if string.strip_edges().begins_with("<<END BRANCH>>"):
		return true
	return false
