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
	event_icon = load("res://addons/dialogic/Editor/Images/Event Icons/Main Icons/label.svg")
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

func _get_property_list() -> Array:
	var p_list = []
	
	# fill the p_list with dictionaries like this one:
#	p_list.append({
#		"name":"Character", # Must be the same as the corresponding property that it edits!
#		"type":TYPE_OBJECT,	# Defines the type of editor (LineEdit, Selector, etc.)
#		"location": Location.HEADER,	# Definest the location
#		"usage":PROPERTY_USAGE_DEFAULT,	
#		"dialogic_type":DialogicValueType.Character,	# Additional information for resource pickers
#		"hint_string":"Character:"		# Text that will be displayed in front of the field
#		})
	p_list.append({
		"name":"Text", # Must be the same as the corresponding property that it edits!
		"type":TYPE_STRING,	# Defines the type of editor (LineEdit, Selector, etc.)
		"location": Location.HEADER,	# Definest the location
		"usage":PROPERTY_USAGE_DEFAULT,	
		"hint_string":"Comment:"		# Text that will be displayed in front of the field
		})
	return p_list
