tool
extends DialogicEvent
class_name DialogicCallNodeEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var Path: String = ""
var Method:String = ""
var Arguments:Array=[]

var Wait:bool = false

func _execute() -> void:
	if Path.begins_with('root'):
		Path = "/"+Path
	if not "/" in Path and dialogic.get_node('/root').has_node(Path):
		Path = "/root/"+Path
	
	var n = dialogic.get_node_or_null(Path)
	if n:
		if n.has_method(Method):
			if Wait:
				yield(n.callv(Method, Arguments), "completed")
			else:
				n.callv(Method, Arguments)
	
	finish()

################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Call Node"
	set_default_color('Color1')
	event_category = Category.GODOT
	event_sorting_index = 3
	


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "call_node"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"path"		: "Path",
		"method"	: "Method",
		"args"		: "Arguments",
		"wait"		: "Wait"
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('Path', ValueType.SinglelineText, 'Path:')
	add_body_edit('Method', ValueType.SinglelineText, 'Method:')
	add_body_edit('Wait', ValueType.Bool, 'Wait:')
	add_body_line_break()
	add_body_edit('Arguments', ValueType.StringArray, 'Arguments:')
