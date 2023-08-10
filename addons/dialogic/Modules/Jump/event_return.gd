@tool
class_name DialogicReturnEvent
extends DialogicEvent

## Event that will make dialogic jump back to the last jump point.



################################################################################
## 						EXECUTION
################################################################################

func _execute() -> void:
	if !dialogic.Jump.is_jump_stack_empty():
		dialogic.Jump.resume_from_last_jump()
	else:
		dialogic.end_timeline()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Return"
	set_default_color('Color4')
	event_category = "Flow"
	event_sorting_index = 5
	expand_by_default = false


func _get_icon() -> Resource:
	return load(self.get_script().get_path().get_base_dir().path_join('icon_return.svg'))


################################################################################
## 						SAVING/LOADING
################################################################################
func to_text() -> String:
	return "return"


func from_text(string:String) -> void:
	pass


func is_valid_event(string:String) -> bool:
	if string.strip_edges() == "return":
		return true
	return false


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_label('Return')
