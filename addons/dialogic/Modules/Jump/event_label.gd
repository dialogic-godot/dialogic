@tool
class_name DialogicLabelEvent
extends DialogicEvent

## Event that is used as an anchor. You can use the DialogicJumpEvent to jump to this point.


### Settings

## Used to identify the label. Duplicate names in a timeline will mean it always chooses the first.
var name: String = ""
var display_name: String = ""



################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	# This event is mainly implemented in the Jump subsystem.
	dialogic.Jump.passed_label.emit(
		{
			"identifier": name,
			"display_name": get_property_translated("display_name"),
			"display_name_orig": display_name,
			"timeline": DialogicResourceUtil.get_unique_identifier(dialogic.current_timeline.resource_path)
		})
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Label"
	set_default_color('Color4')
	event_category = "Flow"
	event_sorting_index = 3


func _get_icon() -> Resource:
	return load(self.get_script().get_path().get_base_dir().path_join('icon_label.png'))


################################################################################
## 						SAVING/LOADING
################################################################################
func to_text() -> String:
	if display_name.is_empty():
		return "label "+name
	else:
		return "label "+name+ " ("+display_name+")"



func from_text(string:String) -> void:
	var regex = RegEx.create_from_string(r'label +(?<name>[^(]+)(\((?<display_name>.+)\))?')
	var result := regex.search(string.strip_edges())
	if result:
		name = result.get_string('name').strip_edges()
		display_name = result.get_string('display_name').strip_edges()


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
		"display" 		: {"property": "display_name", "default": ""},
	}


func _get_translatable_properties() -> Array:
	return ["display_name"]


func _get_property_original_translation(property_name:String) -> String:
	match property_name:
		'display_name':
			return display_name
	return ''

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('name', ValueType.SINGLELINE_TEXT, {'left_text':'Label', 'autofocus':true})
	add_body_edit('display_name', ValueType.SINGLELINE_TEXT, {'left_text':'Display Name:'})


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
