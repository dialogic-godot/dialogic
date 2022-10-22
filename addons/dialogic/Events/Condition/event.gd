@tool
extends DialogicEvent
class_name DialogicConditionEvent

enum ConditionTypes {IF, ELIF, ELSE}

# DEFINE ALL PROPERTIES OF THE EVENT
var ConditionType = ConditionTypes.IF
var Condition :String = ""

func _execute() -> void:
	if ConditionType == ConditionTypes.ELSE:
		finish()
		return
	
	if Condition.is_empty(): Condition = "true"
	
	var result = dialogic.execute_condition(Condition)
	if not result:
		var idx = dialogic.current_event_idx
		var ignore = 1
		while true:
			idx += 1
			if not dialogic.current_timeline.get_event(idx):
				break
			if ignore == 0 and dialogic.current_timeline.get_event(idx) is DialogicConditionEvent:
				break
			if dialogic.current_timeline.get_event(idx).can_contain_events:
				ignore += 1
			elif dialogic.current_timeline.get_event(idx) is DialogicEndBranchEvent:
				ignore -= 1
			elif ignore == 0:
				break
		
		dialogic.current_event_idx = idx-1
	finish()

# only called if the previous event was an end-branch event
# return true if this event should be executed if the previous event was an end-branch event
func should_execute_this_branch() -> bool:
	return ConditionType == ConditionTypes.IF


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Condition"
	set_default_color('Color3')
	event_category = Category.LOGIC
	event_sorting_index = 0
	can_contain_events = true
	continue_at_end = true


# return a control node that should show on the END BRANCH node
func get_end_branch_control() -> Control:
	return load(get_script().resource_path.get_base_dir().path_join('Condition_End.tscn')).instantiate()

################################################################################
## 						SAVING/LOADING
################################################################################

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func to_text() -> String:
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
func from_text(string:String) -> void:
	
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
func is_valid_event(string:String) -> bool:
	if (string.strip_edges().begins_with('if ') or string.strip_edges().begins_with('elif ') or string.strip_edges().begins_with('else')) and string.strip_edges().ends_with(':'):
		return true
	return false


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('ConditionType', ValueType.FixedOptionSelector, '', '', {
		'selector_options': [
			{
				'label': 'IF',
				'value': ConditionTypes.IF,
			},
			{
				'label': 'ELIF',
				'value': ConditionTypes.ELIF,
			},
			{
				'label': 'ELSE',
				'value': ConditionTypes.ELSE,
			}
		], 'disabled':true})
	add_header_edit('Condition', ValueType.Condition, '', '', {}, 'ConditionType != %s'%ConditionTypes.ELSE)
