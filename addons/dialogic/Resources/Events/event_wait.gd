tool
extends DialogicEvent


# DEFINE ALL PROPERTIES OF THE EVENT
var Time :float = 1.0

func _execute() -> void:
	yield(dialogic_game_handler.get_tree().create_timer(Time), "timeout")
	finish()

################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Wait"
	event_icon = load("res://addons/dialogic/Images/Event Icons/Main Icons/wait-seconds.svg")
	event_color = Color(0.352295, 0.591299, 0.609375)
	event_category = Category.OTHER
	event_sorting_index = 0


################################################################################
## 						SAVING/LOADING
################################################################################

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func get_as_string_to_store() -> String:
	var result_string = ""
	
	result_string = "Wait "+str(Time)
	
	return result_string


## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func load_from_string_to_store(string:String):
	
	Time = float(string.trim_prefix('Wait ').strip_edges())


# RETURN TRUE IF THE GIVEN LINE SHOULD BE LOADED AS THIS EVENT
static func is_valid_event_string(string:String):
	
	if string.begins_with('Wait '):
		return true
	
	return false


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func _get_property_list() -> Array:
	var p_list = []
	
	# fill the p_list with dictionaries like this one:
	p_list.append({
		"name":"Time", # Must be the same as the corresponding property that it edits!
		"type":TYPE_REAL,	# Defines the type of editor (LineEdit, Selector, etc.)
		"location": Location.HEADER,	# Definest the location
		"usage":PROPERTY_USAGE_DEFAULT,	
		"dialogic_type":DialogicValueType.Float,	# Additional information for resource pickers
		"hint_string":"Seconds:"		# Text that will be displayed in front of the field
		})
	
	return p_list
