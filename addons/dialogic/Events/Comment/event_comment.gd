@tool
class_name DialogicCommentEvent
extends DialogicEvent

## Event that does nothing but store a comment string. Will print the comment in debug builds.


### Settings

## Content of the comment.
var text :String = ""


################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	print("[Dialogic Comment] #",  text)
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Comment"
	set_default_color('Color6')
	event_category = Category.Helpers
	event_sorting_index = 0
	continue_at_end = true


################################################################################
## 						SAVING/LOADING
################################################################################

func to_text() -> String:
	var result_string = "# "+text
	return result_string


func from_text(string:String) -> void:
	text = string.trim_prefix("# ")


func is_valid_event(string:String) -> bool:
	if string.strip_edges().begins_with('#'):
		return true
	return false


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('text', ValueType.SinglelineText, '#')
