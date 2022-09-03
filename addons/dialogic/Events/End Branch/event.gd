@tool
extends DialogicEvent
class_name DialogicEndBranchEvent

var this_is_an_end_event

func _execute() -> void:
	dialogic.current_event_idx = find_next_index()-1
	finish()

func find_next_index():
	var idx = dialogic.current_event_idx
#
#	# if the next event is a boringly normal event, just go there
#	if dialogic.current_timeline.get_event(idx+1) and !dialogic.current_timeline.get_event(idx+1).can_contain_events:
#		return idx+1
#
#	# if the next event
#	if dialogic.current_timeline.get_event(idx+1) and dialogic.current_timeline.get_event(idx+1).should_execute_this_branch():
#		return idx+1
#
	var ignore = 1
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

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "End Branch"
	event_color = Color(1,1,1,1)
	event_category = Category.LOGIC
	event_sorting_index = 0
	disable_editor_button = true
	continue_at_end = true


################################################################################
## 						SAVING/LOADING
################################################################################

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func to_text() -> String:
	
	return "<<END BRANCH>>"


## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func from_text(string:String) -> void:
	
	# fill your properies by interpreting the string
	
	pass


# RETURN TRUE IF THE GIVEN LINE SHOULD BE LOADED AS THIS EVENT
func is_valid_event(string:String) -> bool:
	
	if string.strip_edges().begins_with("<<END BRANCH>>"):
		return true
	return false
