@tool
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
	set_default_color('Color6')
	event_category = Category.OTHER
	event_sorting_index = 0
	continue_at_end = true


################################################################################
## 						SAVING/LOADING
################################################################################

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func to_text() -> String:
	var result_string = "# "+Text
	return result_string


## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func from_text(string:String) -> void:
	Text = string.trim_prefix("# ")


# RETURN TRUE IF THE GIVEN LINE SHOULD BE LOADED AS THIS EVENT
func is_valid_event(string:String) -> bool:
	if string.strip_edges().begins_with('#'):
		return true
	return false


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('Text', ValueType.SinglelineText, '#')
