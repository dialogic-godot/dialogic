tool
extends DialogicEvent


# DEFINE ALL PROPERTIES OF THE EVENT


func _execute() -> void:
	for character in dialogic_game_handler.get_joined_characters():
		dialogic_game_handler.remove_portrait(character)
	dialogic_game_handler.end_timeline()


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "End Timeline"
	event_color = Color("#f04438")
	event_category = Category.TIMELINE
	event_sorting_index = 3
	


################################################################################
## 						SAVING/LOADING
################################################################################

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func get_as_string_to_store() -> String:
	var result_string = ""
	
	result_string = "End Timeline"
	
	return result_string


## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func load_from_string_to_store(string:String):
	
	pass


# RETURN TRUE IF THE GIVEN LINE SHOULD BE LOADED AS THIS EVENT
static func is_valid_event_string(string:String):
	if string.strip_edges().to_lower() == "end timeline":
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
	
	return p_list
