tool
extends DialogicEvent


# DEFINE ALL PROPERTIES OF THE EVENT
var SecondsTime :float = 1.0

func _execute() -> void:
	dialogic_game_handler.current_state = dialogic_game_handler.states.WAITING
	yield(dialogic_game_handler.get_tree().create_timer(SecondsTime), "timeout")
	dialogic_game_handler.current_state = dialogic_game_handler.states.IDLE
	finish()

################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Wait"
	event_color = Color("#657084")
	event_category = Category.TIMELINE
	event_sorting_index = 0


################################################################################
## 						SAVING/LOADING
################################################################################

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func get_as_string_to_store() -> String:
	var result_string = ""
	
	result_string = '[wait time="'+str(SecondsTime)+'"]'
	
	return result_string


## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func load_from_string_to_store(string:String):
	
	var data = parse_shortcode_parameters(string)
	
	SecondsTime = data.get('time', 1)



# RETURN TRUE IF THE GIVEN LINE SHOULD BE LOADED AS THIS EVENT
static func is_valid_event_string(string:String):
	
	if string.begins_with('[wait'):
		return true
	
	return false


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func _get_property_list() -> Array:

	clear_editor()
	add_header_edit('SecondsTime', ValueType.Float, 'Seconds:')
	
	return editor_list
