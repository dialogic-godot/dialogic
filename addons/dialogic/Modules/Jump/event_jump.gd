@tool
class_name DialogicJumpEvent
extends DialogicEvent

## Event that allows starting another timeline. Also can jump to a label in that or the current timeline.


### Settings

## The timeline to jump to, if null then it's the current one. This setting should be a dialogic timeline resource.
var timeline :DialogicTimeline = null:
	get:
		if timeline == null:
			if !_timeline_file.is_empty():
				if _timeline_file.contains("res://"):
					return load(_timeline_file)
				else: 
					return load(Dialogic.find_timeline(_timeline_file))
		return timeline
## If not empty, the event will try to find a Label event with this set as name. Empty by default..
var label_name : String = ""


### Helpers

## Path to the timeline. Mainly used by the editor.
var _timeline_file: String = ""


################################################################################
## 						EXECUTION
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


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Jump"
	set_default_color('Color4')
	event_category = "Flow"
	event_sorting_index = 4


func _get_icon() -> Resource:
	return load(self.get_script().get_path().get_base_dir().path_join('icon_jump.png'))


################################################################################
## 						SAVING/LOADING
################################################################################
func to_text() -> String:
	var result := "jump "
	if _timeline_file:
		result += _timeline_file+'/'
		if label_name:
			result += label_name
	elif label_name:
		result += label_name
	return result


func from_text(string:String) -> void:
	var result := RegEx.create_from_string('jump (?<timeline>\\w*\\/)?(?<label>\\w*)?').search(string.strip_edges())
	if result:
		_timeline_file = result.get_string('timeline').trim_suffix('/')
		label_name = result.get_string('label')


func is_valid_event(string:String) -> bool:
	if string.strip_edges().begins_with("jump"):
		return true
	return false


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		"timeline"		: {"property": "_timeline_file", 	"default": null, 
							"suggestions": get_timeline_suggestions},
		"label"			: {"property": "label_name", 		"default": ""},
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('_timeline_file', ValueType.COMPLEX_PICKER, {'left_text':'Jump to',
		'file_extension': '.dtl',
		'suggestions_func': get_timeline_suggestions,
		'editor_icon': ["TripleBar", "EditorIcons"],
		'empty_text': '(this timeline)',
		'autofocus':true
	})
	add_header_edit("label_name", ValueType.COMPLEX_PICKER, {'left_text':"at", 
		'empty_text':'the beginning',
		'suggestions_func':get_label_suggestions,
		'editor_icon':["ArrowRight", "EditorIcons"]})


func get_timeline_suggestions(filter:String= "") -> Dictionary:
	var suggestions := {}
	var resources := DialogicUtil.list_resources_of_type('.dtl')
	
	suggestions['(this timeline)'] = {'value':'', 'editor_icon':['GuiRadioUnchecked', 'EditorIcons']}
	
	for resource in Engine.get_main_loop().get_meta('dialogic_timeline_directory').keys():
		suggestions[resource] = {'value': resource, 'tooltip':Engine.get_main_loop().get_meta('dialogic_timeline_directory')[resource], 'editor_icon': ["TripleBar", "EditorIcons"]}
	return suggestions


func get_label_suggestions(filter:String="") -> Dictionary:
	var suggestions := {}
	suggestions['at the beginning'] = {'value':'', 'editor_icon':['GuiRadioUnchecked', 'EditorIcons']}
	
	if _timeline_file in Engine.get_main_loop().get_meta('dialogic_label_directory').keys():
		for label in Engine.get_main_loop().get_meta('dialogic_label_directory')[_timeline_file]:
			suggestions[label] = {'value': label, 'tooltip':label, 'editor_icon': ["ArrowRight", "EditorIcons"]}
	return suggestions


####################### CODE COMPLETION ########################################
################################################################################

func _get_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit, line:String, word:String, symbol:String) -> void:
	if symbol == ' ' and line.count(' ') == 1:
		CodeCompletionHelper.suggest_timelines(TextNode, CodeEdit.KIND_MEMBER, event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.6))
		CodeCompletionHelper.suggest_labels(TextNode, '', '\n', event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.6))
	if symbol == '/':
		CodeCompletionHelper.suggest_labels(TextNode, line.strip_edges().trim_prefix('jump ').trim_suffix('/'+String.chr(0xFFFF)).strip_edges(), '\n', event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.6))


func _get_start_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit) -> void:
	TextNode.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'jump', 'jump ', event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.3))


#################### SYNTAX HIGHLIGHTING #######################################
################################################################################

func _get_syntax_highlighting(Highlighter:SyntaxHighlighter, dict:Dictionary, line:String) -> Dictionary:
	dict[line.find('jump')] = {"color":event_color.lerp(Highlighter.normal_color, 0.3)}
	dict[line.find('jump')+4] = {"color":event_color.lerp(Highlighter.normal_color, 0.5)}
	return dict
