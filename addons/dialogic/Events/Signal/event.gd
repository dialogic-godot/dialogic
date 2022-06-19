tool
extends DialogicEvent


# DEFINE ALL PROPERTIES OF THE EVENT
var Argument: String = ""

func _execute() -> void:
	dialogic_game_handler.emit_signal('signal_event', Argument)
	finish()


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Signal"
	event_color = Color("#0ca5eb")
	event_category = Category.GODOT
	event_sorting_index = 0


################################################################################
## 						SAVING/LOADING
################################################################################

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func get_as_string_to_store() -> String:
	var result_string = ""
	
	result_string = '[signal arg="'+Argument+'"]'
	
	return result_string


## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func load_from_string_to_store(string:String):
	
	var data = parse_shortcode_parameters(string)
	
	Argument = data.get('arg', '')


# RETURN TRUE IF THE GIVEN LINE SHOULD BE LOADED AS THIS EVENT
static func is_valid_event_string(string:String):
	
	if string.strip_edges().begins_with('[signal'):
		return true
	
	return false


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func _get_property_list() -> Array:
	
	clear_editor()
	add_header_edit('Argument', ValueType.SinglelineText, 'Argument:')
	
	return editor_list
