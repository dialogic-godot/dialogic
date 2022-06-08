tool
extends DialogicEvent

class_name DialogicEndBranchEvent

var this_is_an_end_event
var parent_event = null

func _execute() -> void:
	dialogic_game_handler.current_event_idx = find_next_index()-1
	finish()

func find_next_index():
	var idx = dialogic_game_handler.current_event_idx
	if not dialogic_game_handler.current_timeline.get_event(idx+1) is DialogicChoiceEvent:
		return idx+1
	var ignore = 1
	while true:
		idx += 1
		if dialogic_game_handler.current_timeline.get_event(idx) is DialogicChoiceEvent:
			ignore += 1
		elif ignore == 1:
			break
		# excuse this, checking like above creates a FUCKING CYCLIC DEPENDENCY....
		elif 'this_is_an_end_event' in dialogic_game_handler.current_timeline.get_event(idx):
			ignore -= 1
		
	return idx

################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "End Branch"
	event_icon = load("res://addons/dialogic/Images/Event Icons/Main Icons/end-branch.svg")
	event_color = Color(0.71306, 0.427338, 0.816406)
	event_category = Category.LOGIC
	event_sorting_index = 0
	disable_editor_button = true
	continue_at_end = true


################################################################################
## 						SAVING/LOADING
################################################################################

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func get_as_string_to_store() -> String:
	
	return "<<END BRANCH>>"


## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func load_from_string_to_store(string:String):
	
	# fill your properies by interpreting the string
	
	pass


# RETURN TRUE IF THE GIVEN LINE SHOULD BE LOADED AS THIS EVENT
static func is_valid_event_string(string:String):
	
	if string.strip_edges() == "<<END BRANCH>>":
		return true
	return false


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func _get_property_list() -> Array:
	var p_list = []
	
	return p_list
