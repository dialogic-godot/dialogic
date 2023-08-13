@tool
class_name DialogicLabelEvent
extends DialogicEvent

## Event that is used as an anchor. You can use the DialogicJumpEvent to jump to this point.


### Settings

## Used to identify the label. Duplicate names in a timeline will mean it always chooses the first.
var name: String = ""


################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	# This event is mainly implemented in the Jump subsystem.
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Label"
	set_default_color('Color4')
	event_category = "Flow"
	event_sorting_index = 3
	continue_at_end = true


func _get_icon() -> Resource:
	return load(self.get_script().get_path().get_base_dir().path_join('icon_label.png'))


################################################################################
## 						SAVING/LOADING
################################################################################
func to_text() -> String:
	return "label "+name


func from_text(string:String) -> void:
	var regex = RegEx.create_from_string('label +(?<name>.+)')
	var result := regex.search(string.strip_edges())
	if result:
		name = result.get_string('name')


func is_valid_event(string:String) -> bool:
	if string.strip_edges().begins_with("label"):
		return true
	return false


# this is only here to provide a list of default values
# this way the module manager can add custom default overrides to this event.
func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		"name" 			: {"property": "name", "default": ""},
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('name', ValueType.SINGLELINE_TEXT, '', '', {'autofocus':true})


####################### CODE COMPLETION ########################################
################################################################################

func _get_start_code_completion(CodeCompletionHelper:Node, TextNode:TextEdit) -> void:
	TextNode.add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, 'label', 'label ', event_color.lerp(TextNode.syntax_highlighter.normal_color, 0.3))


#################### SYNTAX HIGHLIGHTING #######################################
################################################################################

func _get_syntax_highlighting(Highlighter:SyntaxHighlighter, dict:Dictionary, line:String) -> Dictionary:
	dict[line.find('label')] = {"color":event_color.lerp(Highlighter.normal_color, 0.3)}
	dict[line.find('label')+5] = {"color":event_color.lerp(Highlighter.normal_color, 0.5)}
	return dict
