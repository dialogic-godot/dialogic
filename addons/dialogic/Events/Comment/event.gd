tool
extends DialogicEvent
class_name DialogicCommentEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var Text :String = ""

func _execute() -> void:
	print("[Dialogic Comment] #",  Text)
	finish()



################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Comment"

	event_color = Color(0.53125, 0.53125, 0.53125)
	event_category = Category.OTHER
	event_sorting_index = 0
	continue_at_end = true


################################################################################
## 						SAVING/LOADING
################################################################################

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func get_as_string_to_store() -> String:
	var result_string = "# "+Text
	return result_string


## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func load_from_string_to_store(string:String):
	Text = string.trim_prefix("# ")


# RETURN TRUE IF THE GIVEN LINE SHOULD BE LOADED AS THIS EVENT
static func is_valid_event_string(string:String):
	if string.strip_edges().begins_with('#'):
		return true
	return false


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('Text', ValueType.SinglelineText, 'Comment:')
