tool
extends DialogicEvent


# DEFINE ALL PROPERTIES OF THE EVENT
var ImagePath: String = ""

func _execute() -> void:
	dialogic_game_handler.update_background(ImagePath)
	finish()


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Background"
	event_color = Color("#f63d67")
	event_category = Category.AUDIOVISUAL
	event_sorting_index = 0
	


################################################################################
## 						SAVING/LOADING
################################################################################

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func get_as_string_to_store() -> String:
	var result_string = ""
	
	result_string = '[background path="'+ImagePath+'"]'
	
	return result_string


## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func load_from_string_to_store(string:String):
	
	var data = parse_shortcode_parameters(string)
	
	ImagePath = data.get('path', '')


# RETURN TRUE IF THE GIVEN LINE SHOULD BE LOADED AS THIS EVENT
static func is_valid_event_string(string:String):
	
	if string.begins_with('[background'):
		return true
	return false


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('ImagePath', ValueType.SinglelineText, 'Path:')
