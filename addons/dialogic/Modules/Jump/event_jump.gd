@tool
class_name DialogicJumpEvent
extends DialogicEvent

## Event that allows starting another timeline. Also can jump to a label in that or the current timeline.


### Settings

## The timeline to jump to, if null then it's the current one. This setting should be a dialogic timeline resource.
var timeline: DialogicTimeline
## If not empty, the event will try to find a Label event with this set as name. Empty by default..
var label_name := ""


### Helpers

## Used to set the timeline resource from the unique name identifier and vice versa
var timeline_identifier := "":
	get:
		if timeline:
			var identifier := timeline.get_identifier()
			if not identifier.is_empty():
				return identifier
		return timeline_identifier
	set(value):
		timeline_identifier = value
		timeline = DialogicResourceUtil.get_timeline_resource(value)
		if (not timeline_identifier in DialogicResourceUtil.get_label_cache().keys()
				or not label_name in DialogicResourceUtil.get_label_cache()[timeline_identifier]):
			label_name = ""
			ui_update_needed.emit()


#region EXECUTION
################################################################################

func _execute() -> void:
	dialogic.Jump.push_to_jump_stack()
	if timeline and timeline != dialogic.current_timeline:
		dialogic.Jump.switched_timeline.emit({'previous_timeline':dialogic.current_timeline, 'timeline':timeline, 'label':label_name})
		dialogic.start_timeline(timeline, label_name)
	else:
		if label_name:
			dialogic.Jump.jump_to_label(label_name)
			finish()
		else:
			dialogic.start_timeline(dialogic.current_timeline)

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Jump"
	event_description = "Allows going to another timeline or jumping to a label event in this timeline."
	set_default_color('Color4')
	event_category = "Flow"
	event_sorting_index = 4
	help_page_path = "https://docs.dialogic.pro/jump-event.html"


func _get_icon() -> Resource:
	return load(self.get_script().get_path().get_base_dir().path_join('icon_jump.png'))

#endregion


#region SAVING/LOADING
################################################################################
func to_text() -> String:
	var result := "jump "
	if timeline_identifier:
		result += timeline_identifier+'/'
		if label_name:
			result += label_name
	elif label_name:
		result += label_name
	return result


func from_text(string:String) -> void:
	var result := RegEx.create_from_string(r"jump (?<timeline>.*\/)?(?<label>.*)?").search(string.strip_edges())
	if result:
		timeline_identifier = result.get_string('timeline').trim_suffix('/')
		label_name = result.get_string('label')


func is_valid_event(string:String) -> bool:
	if string.strip_edges().begins_with("jump"):
		return true
	return false


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		"timeline"		: {"property": "timeline_identifier", 	"default": null,
							"suggestions": get_timeline_suggestions, "ext_file":true},
		"label"			: {"property": "label_name", 		"default": ""},
	}

#endregion


#region REPRESENTATION
################################################################################

func build_event_editor() -> void:
	add_header_edit('timeline_identifier', ValueType.DYNAMIC_OPTIONS, {'left_text':'Jump to',
		'file_extension': '.dtl',
		'mode'			: 2,
		'suggestions_func': get_timeline_suggestions,
		'icon'	: load("res://addons/dialogic/Editor/Images/Resources/timeline.svg"),
		'empty_text'	: '(this timeline)',
		'autofocus'		: true,
		})
	add_header_edit("label_name", ValueType.DYNAMIC_OPTIONS, {'left_text':"at",
		'empty_text':'the beginning',
		'suggestions_func':get_label_suggestions,
		'editor_icon':["ArrowRight", "EditorIcons"]})


func get_timeline_suggestions(_filter:String= "") -> Dictionary:
	var suggestions := {}

	suggestions['(this timeline)'] = {'value':'', 'editor_icon':['GuiRadioUnchecked', 'EditorIcons']}
	for resource in  DialogicResourceUtil.get_timeline_directory().keys():
		suggestions[resource] = {'value': resource, 'tooltip':DialogicResourceUtil.get_timeline_directory()[resource], 'editor_icon': ["TripleBar", "EditorIcons"]}
	return suggestions


func get_label_suggestions(_filter:String="") -> Dictionary:
	var suggestions := {}
	suggestions['at the beginning'] = {'value':'', 'editor_icon':['GuiRadioUnchecked', 'EditorIcons'], "tooltip":"Starts the timeline from the beginning."}
	if timeline_identifier in DialogicResourceUtil.get_label_cache().keys():
		for label in DialogicResourceUtil.get_label_cache()[timeline_identifier]:
			suggestions[label] = {'value': label, 'tooltip':label, 'editor_icon': ["ArrowRight", "EditorIcons"]}
	if len(suggestions) == 1:
		suggestions["No label events found."] = {'value': "NOTHING", 'tooltip':"By adding label events to this timeline you can jump directly to them.", "disabled":true,}
	if _filter.begins_with("{"):
		for var_path in DialogicUtil.list_variables(DialogicUtil.get_default_variables()):
			suggestions["{"+var_path+"}"] = {'value':"{"+var_path+"}", 'icon':load("res://addons/dialogic/Editor/Images/Pieces/variable.svg")}
	return suggestions

#endregion


#region CODE COMPLETION
################################################################################

func _get_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit, line:String, _word:String, symbol:String) -> void:
	if symbol == ' ' and line.count(' ') == 1:
		CodeCompletionHelper.suggest_labels(TextNode, '', '\n', event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.6))
		CodeCompletionHelper.suggest_timelines(TextNode, CodeEdit.KIND_MEMBER, event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.6))
	if symbol == "{":
		CodeCompletionHelper.suggest_variables(TextNode)
	if symbol == '/':
		CodeCompletionHelper.suggest_labels(TextNode, line.strip_edges().trim_prefix('jump ').trim_suffix('/'+String.chr(0xFFFF)).strip_edges(), '\n', event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.6))


func _get_start_code_completion(_CodeCompletionHelper:Node, TextNode:TextEdit) -> void:
	TextNode.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'jump', 'jump ', event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.3))

#endregion


#region SYNTAX HIGHLIGHTING
################################################################################

func _get_syntax_highlighting(Highlighter:SyntaxHighlighter, dict:Dictionary, line:String) -> Dictionary:
	dict[line.find('jump')] = {"color":event_color.lerp(Highlighter.normal_color, 0.3)}
	dict[line.find('jump')+4] = {"color":event_color.lerp(Highlighter.normal_color, 0.5)}
	return dict

#endregion
