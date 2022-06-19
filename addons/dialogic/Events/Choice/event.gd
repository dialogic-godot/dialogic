tool
extends DialogicEvent
class_name DialogicChoiceEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var Text :String = ""

func _execute() -> void:
	# I have no idea how this event works
	finish()


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Choice"
	event_color = Color("#9e77ec")
	event_category = Category.LOGIC
	event_sorting_index = 0


################################################################################
## 						SAVING/LOADING
################################################################################

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func get_as_string_to_store() -> String:
	var result_string = ""

	result_string = "- "+Text
	
	return result_string


## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func load_from_string_to_store(string:String):
	
	Text = string.strip_edges().trim_prefix("-").strip_edges()


# RETURN TRUE IF THE GIVEN LINE SHOULD BE LOADED AS THIS EVENT
static func is_valid_event_string(string:String) -> bool:
	
	if string.strip_edges().begins_with("-"):
		return true
	
	return false


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func _get_property_list() -> Array:
	
	clear_editor()
	add_header_edit("Text", ValueType.SinglelineText)
	
	return editor_list
