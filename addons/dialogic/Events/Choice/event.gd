@tool
extends DialogicEvent
class_name DialogicChoiceEvent

enum IfFalseActions {HIDE, DISABLE, DEFAULT}

# DEFINE ALL PROPERTIES OF THE EVENT
var Text :String = ""
var Condition:String = ""
var IfFalseAction = IfFalseActions.DEFAULT

func _execute() -> void:
	# I have no idea how this event works
	finish()

func get_required_subsystems() -> Array:
	return [
				{'name':'Choices',
				'subsystem': get_script().resource_path.get_base_dir().path_join('Subsystem_Choices.gd'),
				'settings':get_script().resource_path.get_base_dir().path_join('ChoicesSettings.tscn'),
				},
			]


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Choice"
	set_default_color('Color3')
	event_category = Category.LOGIC
	event_sorting_index = 0
	can_contain_events = true
	needs_parent_event = true
	expand_by_default = false

# if needs_parent_event is true, this needs to return true if the event is that event
func is_expected_parent_event(event:DialogicEvent):
	return event is DialogicTextEvent

# return a control node that should show on the END BRANCH node
func get_end_branch_control() -> Control:
	return load(get_script().resource_path.get_base_dir().path_join('Choice_End.tscn')).instantiate()

################################################################################
## 						SAVING/LOADING
################################################################################

## THIS RETURNS A READABLE REPRESENTATION, BUT HAS TO CONTAIN ALL DATA (This is how it's stored)
func to_text() -> String:
	var result_string = ""

	result_string = "- "+Text
	if Condition:
		result_string += " [if "+Condition+"]"
	
	if IfFalseAction == IfFalseActions.HIDE:
		result_string += " [else hide]"
	elif IfFalseAction == IfFalseActions.DISABLE:
		result_string += " [else disable]"
	
	return result_string


## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func from_text(string:String) -> void:
	var regex = RegEx.new()
	regex.compile('- (?<text>[^\\[]*)(\\[if (?<condition>[^\\]]+)])?\\s?(\\[else (?<else_option>[^\\]\\n]*)\\])?')
	var result = regex.search(string.strip_edges())
	if result == null:
		return
	Text = result.get_string('text')
	Condition = result.get_string('condition')
	if result.get_string('else_option'):
		IfFalseAction = {
			'default':IfFalseActions.DEFAULT, 
			'hide':IfFalseActions.HIDE,
			'disable':IfFalseActions.DISABLE}.get(result.get_string('else_option'), IfFalseActions.DEFAULT)

# RETURN TRUE IF THE GIVEN LINE SHOULD BE LOADED AS THIS EVENT
func is_valid_event(string:String) -> bool:
	if string.strip_edges().begins_with("-"):
		return true
	return false

func can_be_translated():
	return true
	
func get_original_translation_text():
	return Text


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit("Text", ValueType.SinglelineText)
	add_body_edit("Condition", ValueType.Condition, 'if ')
	add_body_edit("IfFalseAction", ValueType.FixedOptionSelector, 'else ', '', {
		'selector_options': [
			{
				'label': 'Default',
				'value': IfFalseActions.DEFAULT,
			},
			{
				'label': 'Hide',
				'value': IfFalseActions.HIDE,
			},
			{
				'label': 'Disable',
				'value': IfFalseActions.DISABLE,
			}
		]}, '!Condition.is_empty()')
