tool
extends DialogicEvent

class_name DialogicConditionEvent

enum ConditionTypes {IF, ELIF, ELSE}

# DEFINE ALL PROPERTIES OF THE EVENT
var ConditionType = ConditionTypes.IF
var Condition :String = "true"

func _execute() -> void:
	if ConditionType == ConditionTypes.ELSE:
		finish()
		return
	
	var expr = Expression.new()
	expr.parse(Condition)
	var result = expr.execute()
	if not result:
		var idx = dialogic_game_handler.current_event_idx
		var ignore = 1
		# this will go through the next events, until there is a event that is not a choice and on the same level as this one
		while true:
			idx += 1
			if not dialogic_game_handler.current_timeline.get_event(idx):
				break
			if dialogic_game_handler.current_timeline.get_event(idx) is DialogicChoiceEvent:
				ignore += 1
			elif dialogic_game_handler.current_timeline.get_event(idx) is DialogicEndBranchEvent:
				ignore -= 1
			elif ignore == 0:
				break
			# excuse this, checking like above creates a FUCKING CYCLIC DEPENDENCY....
			elif 'Condition' in dialogic_game_handler.current_timeline.get_event(idx):
				ignore += 1
			
		dialogic_game_handler.current_event_idx = idx-1
	finish()


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Condition"
	event_color = Color("#7622FF")
	event_category = Category.LOGIC
	event_sorting_index = 0
	continue_at_end = true


################################################################################
## 						SAVING/LOADING
################################################################################

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func get_as_string_to_store() -> String:
	var result_string = ""
	
	match ConditionType:
		ConditionTypes.IF:
			result_string = 'if '+Condition+':'
		ConditionTypes.ELIF:
			result_string = 'elif '+Condition+':'
		ConditionTypes.ELSE:
			result_string = 'else:'
	
	return result_string


## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func load_from_string_to_store(string:String):
	
	if string.strip_edges().begins_with('if'):
		Condition = string.strip_edges().trim_prefix('if ').trim_suffix(':').strip_edges()
		ConditionType = ConditionTypes.IF
	elif string.strip_edges().begins_with('elif'):
		Condition = string.strip_edges().trim_prefix('elif ').trim_suffix(':').strip_edges()
		ConditionType = ConditionTypes.ELIF
	elif string.strip_edges().begins_with('else'):
		Condition = ""
		ConditionType = ConditionTypes.ELSE


# RETURN TRUE IF THE GIVEN LINE SHOULD BE LOADED AS THIS EVENT
static func is_valid_event_string(string:String):
	if (string.strip_edges().begins_with('if ') or string.strip_edges().begins_with('elif ') or string.strip_edges().begins_with('else')) and string.strip_edges().ends_with(':'):
		return true
	return false


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func _get_property_list() -> Array:
	var p_list = []
	
	# fill the p_list with dictionaries like this one:
	p_list.append({
		"name":"ConditionType", # Must be the same as the corresponding property that it edits!
		"type":TYPE_INT,	# Defines the type of editor (LineEdit, Selector, etc.)
		"location": Location.HEADER,	# Definest the location
		"usage":PROPERTY_USAGE_DEFAULT,	
		"dialogic_type":DialogicValueType.FixedOptionSelector,	# Additional information for resource pickers
		"selector_options":{"if":ConditionTypes.IF, "elif":ConditionTypes.ELIF, "else":ConditionTypes.ELSE},
		'disabled': true,
		"hint_string":""		# Text that will be displayed in front of the field
		})
	p_list.append({
		"name":"Condition", # Must be the same as the corresponding property that it edits!
		"type":TYPE_STRING,	# Defines the type of editor (LineEdit, Selector, etc.)
		"location": Location.HEADER,	# Definest the location
		"usage":PROPERTY_USAGE_DEFAULT,	
		"dialogic_type":DialogicValueType.SinglelineText,	# Additional information for resource pickers
		"hint_string":""		# Text that will be displayed in front of the field
		})
	
	return p_list
