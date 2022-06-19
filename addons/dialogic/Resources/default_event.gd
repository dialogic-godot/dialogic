tool
extends DialogicEvent


# DEFINE ALL PROPERTIES OF THE EVENT
# var MySetting :String = ""

func _execute() -> void:
	# I have no idea how this event works
	finish()


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Default"
	event_color = Color("#ffffff")
	event_category = Category.MAIN
	event_sorting_index = 0
	


################################################################################
## 						SAVING/LOADING
################################################################################

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func get_as_string_to_store() -> String:
	var result_string = ""
	
	# fill the result_string with the properties
	
	return result_string


## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func load_from_string_to_store(string:String):
	
	# fill your properies by interpreting the string
	
	pass


# RETURN TRUE IF THE GIVEN LINE SHOULD BE LOADED AS THIS EVENT
static func is_valid_event_string(string:String):
	
	# check the string and maybe return true
	
	return false


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func _get_property_list() -> Array:
	
	clear_editor()
	
	return editor_list
