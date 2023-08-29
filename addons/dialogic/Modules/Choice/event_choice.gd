@tool
class_name DialogicChoiceEvent
extends DialogicEvent

## Event that allows adding choices. Needs to go after a text event (or another choices EndBranch).

enum ElseActions {HIDE, DISABLE, DEFAULT}


### Settings
## The text that is displayed on the choice button.
var text :String = ""
## If not empty this condition will determine if this choice is active.
var condition: String = ""
## Determines what happens if  [condition] is false. Default will use the action set in the settings.
var else_action: = ElseActions.DEFAULT
## The text that is displayed if [condition] is false and [else_action] is Disable. 
## If empty [text] will be used for disabled button as well.
var disabled_text: String = ""


################################################################################
## 						EXECUTION
################################################################################

func _execute() -> void:
	# This event is mostly a placeholder that's used to indicate a position. 
	# Only the selected choice is reached. 
	# However mainly the Choices Subsystem queries the events 
	#   to find the choices that belong to the question.
	if !dialogic.Choices.last_question_info.has('choices'):
		finish()
		return
	if dialogic.has_subsystem('History'):
		var all_choices : Array = dialogic.Choices.last_question_info['choices']
		if dialogic.has_subsystem('VAR'):
			dialogic.History.store_simple_history_entry(dialogic.VAR.parse_variables(text), event_name, {'all_choices': all_choices})
		else:
			dialogic.History.store_simple_history_entry(text, event_name, {'all_choices': all_choices})
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Choice"
	set_default_color('Color3')
	event_category = "Flow"
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
	if else_action == ElseActions.HIDE:
		shortcode += 'else="hide"'
	elif else_action == ElseActions.DISABLE:
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
			'default':ElseActions.DEFAULT, 
			'hide':ElseActions.HIDE,
			'disable':ElseActions.DISABLE}.get(shortcode_params.get('else', ''), ElseActions.DEFAULT)
		
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
	add_header_edit("text", ValueType.SINGLELINE_TEXT, '','', {'autofocus':true})
	add_body_edit("condition", ValueType.CONDITION, 'if ')
	add_body_edit("else_action", ValueType.FIXED_OPTION_SELECTOR, 'else ', '', {
		'selector_options': [
			{
				'label': 'Default',
				'value': ElseActions.DEFAULT,
			},
			{
				'label': 'Hide',
				'value': ElseActions.HIDE,
			},
			{
				'label': 'Disable',
				'value': ElseActions.DISABLE,
			}
		]}, '!condition.is_empty()')
	add_body_edit("disabled_text", ValueType.SINGLELINE_TEXT, 'Disabled text:', '', 
			{'placeholder':'(Empty for same)'}, 'allow_alt_text()')


func allow_alt_text() -> bool:
	return condition and (
		else_action == ElseActions.DISABLE or 
		(else_action == ElseActions.DEFAULT and 
		ProjectSettings.get_setting("dialogic/choices/def_false_behaviour", 0) == 1))


####################### CODE COMPLETION ########################################
################################################################################

func _get_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit, line:String, word:String, symbol:String) -> void:
	if !'[' in line:
		return
	
	if symbol == '[':
		if line.count('[') == 1:
			TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, 'if', 'if ', TextNode.syntax_highlighter.code_flow_color)
		elif line.count('[') > 1:
			TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, 'else', 'else="', TextNode.syntax_highlighter.code_flow_color)
	if symbol == ' ' and '[else' in line:
		TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, 'alt_text', 'alt_text="', event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.5))
	elif symbol == '{':
		CodeCompletionHelper.suggest_variables(TextNode)
	if (symbol == '=' or symbol == '"') and line.count('[') > 1 and !'" ' in line:
		TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, 'default', "default", event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.5), null, '"')
		TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, 'hide', "hide", event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.5), null, '"')
		TextNode.add_code_completion_option(CodeEdit.KIND_MEMBER, 'disable', "disable", event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.5), null, '"')


#################### SYNTAX HIGHLIGHTING #######################################
################################################################################

func _get_syntax_highlighting(Highlighter:SyntaxHighlighter, dict:Dictionary, line:String) -> Dictionary:
	dict[0] = {'color':event_color}
	if '[' in line:
		dict[line.find('[')] = {"color":Highlighter.normal_color}
		dict = Highlighter.color_word(dict, Highlighter.code_flow_color, line, 'if', line.find('['), line.find(']'))
		dict = Highlighter.color_condition(dict, line, line.find('['), line.find(']'))
		dict = Highlighter.color_shortcode_content(dict, line, line.find(']'), 0,event_color)
	return dict
