@tool
extends DialogicEvent
class_name DialogicChoiceEvent

enum IfFalseActions {HIDE, DISABLE, DEFAULT}

# DEFINE ALL PROPERTIES OF THE EVENT
var Text :String = ""
var DisabledText:String = ""
var Condition:String = ""
var IfFalseAction = IfFalseActions.DEFAULT

func _execute() -> void:
	# This event is basically a placeholder only used to indicate a position. 
	# It is never really reached. Instead the Subsystem_Choices queries the events 
	#   to find the choices that belong to the question.  
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

	result_string = "- "+Text.strip_edges()
	if Condition:
		result_string += " [if "+Condition+"]"
	
	
	var shortcode = '['
	if IfFalseAction == IfFalseActions.HIDE:
		shortcode += 'else="hide"'
	elif IfFalseAction == IfFalseActions.DISABLE:
		shortcode += 'else="disable"'
	
	if DisabledText:
		shortcode += " alt_text="+'"'+DisabledText+'"'
	
	if len(shortcode) > 1:
		result_string += shortcode + "]"
	return result_string


## THIS HAS TO READ ALL THE DATA FROM THE SAVED STRING (see above) 
func from_text(string:String) -> void:
	var regex = RegEx.new()
	regex.compile('- (?<text>[^\\[]*)(\\[if (?<condition>[^\\]]+)])?\\s?(\\s*\\[(?<shortcode>.*)\\])?')
	var result = regex.search(string.strip_edges())
	if result == null:
		return
	Text = result.get_string('text')
	Condition = result.get_string('condition')
	if result.get_string('shortcode'):
		var shortcode_params = parse_shortcode_parameters(result.get_string('shortcode'))
		IfFalseAction = {
			'default':IfFalseActions.DEFAULT, 
			'hide':IfFalseActions.HIDE,
			'disable':IfFalseActions.DISABLE}.get(shortcode_params.get('else', ''), IfFalseActions.DEFAULT)
		
		DisabledText = shortcode_params.get('alt_text', '')

# RETURN TRUE IF THE GIVEN LINE SHOULD BE LOADED AS THIS EVENT
func is_valid_event(string:String) -> bool:
	if string.strip_edges().begins_with("-"):
		return true
	return false

################################################################################
## 						TRANSLATIONS
################################################################################

func _get_translatable_properties() -> Array:
	return ['text', 'disabled_text']

func _get_property_original_translation(property:String) -> String:
	match property:
		'text':
			return Text
		'disabled_text':
			return DisabledText
	return ''

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
	add_body_edit("DisabledText", ValueType.SinglelineText, 'Disabled text:', '', {'placeholder':'(Empty for same)'}, 'allow_alt_text()')

func allow_alt_text() -> bool:
	return Condition and (IfFalseAction == IfFalseActions.DISABLE or (IfFalseAction == IfFalseActions.DEFAULT and DialogicUtil.get_project_setting("dialogic/choices/def_false_behaviour", 0) == 1))
