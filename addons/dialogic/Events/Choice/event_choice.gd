@tool
class_name DialogicChoiceEvent
extends DialogicEvent

## Event that allows adding choices. Needs to go after a text event (or another choices EndBranch).

enum ElseActions {Hide, Disable, Default}


### Settings
## The text that is displayed on the choice button.
var text :String = ""
## If not empty this condition will determine if this choice is active.
var condition: String = ""
## Determines what happens if  [condition] is false. Default will use the action set in the settings.
var else_action: = ElseActions.Default
## The text that is displayed if [condition] is false and [else_action] is Disable. 
## If empty [text] will be used for disabled button as well.
var disabled_text: String = ""


################################################################################
## 						EXECUTION
################################################################################

func _execute() -> void:
	# This event is basically a placeholder only used to indicate a position. 
	# It is never really reached. Instead the Subsystem_Choices queries the events 
	#   to find the choices that belong to the question.  
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Choice"
	set_default_color('Color3')
	event_category = Category.Logic
	event_sorting_index = 0
	can_contain_events = true
	needs_parent_event = true
	expand_by_default = false


# if needs_parent_event is true, this needs to return true if the event is that event
func is_expected_parent_event(event:DialogicEvent) -> bool:
	return event is DialogicTextEvent


# return a control node that should show on the END BRANCH node
func get_end_branch_control() -> Control:
	return load(get_script().resource_path.get_base_dir().path_join('ui_choice_end.tscn')).instantiate()

################################################################################
## 						SAVING/LOADING
################################################################################

func to_text() -> String:
	var result_string := ""

	result_string = "- "+text.strip_edges()
	if condition:
		result_string += " [if "+condition+"]"
	
	
	var shortcode = '['
	if else_action == ElseActions.Hide:
		shortcode += 'else="hide"'
	elif else_action == ElseActions.Disable:
		shortcode += 'else="disable"'
	
	if disabled_text:
		shortcode += " alt_text="+'"'+disabled_text+'"'
	
	if len(shortcode) > 1:
		result_string += shortcode + "]"
	return result_string


func from_text(string:String) -> void:
	var regex = RegEx.new()
	regex.compile('- (?<text>[^\\[]*)(\\[if (?<condition>[^\\]]+)])?\\s?(\\s*\\[(?<shortcode>.*)\\])?')
	var result = regex.search(string.strip_edges())
	if result == null:
		return
	text = result.get_string('text')
	condition = result.get_string('condition')
	if result.get_string('shortcode'):
		var shortcode_params = parse_shortcode_parameters(result.get_string('shortcode'))
		else_action = {
			'default':ElseActions.Default, 
			'hide':ElseActions.Hide,
			'disable':ElseActions.Disable}.get(shortcode_params.get('else', ''), ElseActions.Default)
		
		disabled_text = shortcode_params.get('alt_text', '')


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
			return text
		'disabled_text':
			return disabled_text
	return ''


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	add_header_edit("text", ValueType.SinglelineText)
	add_body_edit("condition", ValueType.Condition, 'if ')
	add_body_edit("else_action", ValueType.FixedOptionSelector, 'else ', '', {
		'selector_options': [
			{
				'label': 'Default',
				'value': ElseActions.Default,
			},
			{
				'label': 'Hide',
				'value': ElseActions.Hide,
			},
			{
				'label': 'Disable',
				'value': ElseActions.Disable,
			}
		]}, '!condition.is_empty()')
	add_body_edit("disabled_text", ValueType.SinglelineText, 'Disabled text:', '', 
			{'placeholder':'(Empty for same)'}, 'allow_alt_text()')


func allow_alt_text() -> bool:
	return condition and (
		else_action == ElseActions.Disable or 
		(else_action == ElseActions.Default and 
		DialogicUtil.get_project_setting("dialogic/choices/def_false_behaviour", 0) == 1))
