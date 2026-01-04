@tool
class_name DialogicCommentEvent
extends DialogicEvent

## Event that does nothing but store a comment string. Will print the comment in debug builds.


### Settings

## Content of the comment.
var text := ""


#region EXECUTE
################################################################################

func _execute() -> void:
	print("[Dialogic Comment] #",  text)
	finish()

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Comment"
	event_description = "Has no effect on gameplay, but can help organize your timeline."
	set_default_color('Color9')
	event_category = "Helpers"
	event_sorting_index = 0

#endregion


#region SAVING/LOADING
################################################################################

func to_text() -> String:
	return "# "+text


func from_text(string:String) -> void:
	text = string.trim_prefix("# ")


func is_valid_event(string:String) -> bool:
	if string.strip_edges().begins_with('#'):
		return true
	return false

#endregion


#region EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	add_header_edit('text', ValueType.SINGLELINE_TEXT, {'left_text':'#', 'autofocus':true})

#endregion


#region SYNTAX HIGHLIGHTING
################################################################################

func _get_syntax_highlighting(Highlighter:SyntaxHighlighter, dict:Dictionary, _line:String) -> Dictionary:
	dict[0] = {'color':event_color.lerp(Highlighter.normal_color, 0.3)}
	return dict

#endregion
