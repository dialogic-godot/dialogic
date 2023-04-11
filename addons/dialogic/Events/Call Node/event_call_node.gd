@tool
class_name DialogicCallNodeEvent
extends DialogicEvent

## Event that allows calling a method in a node or autoload.

### Settings

## The path to the node you want to call. You can access autoloads directly. No need to add /root.
var path: String = ""
## The name of the method to call on the given node.
var method: String = ""
## A list of arguments to give to the call.
var arguments: Array = []
## If wait is true, the dialog will only continue once the called method is finished.
var wait: bool = false
## If this is true, the method will not be called. 
## Instead you can activate it during a following text event with the [signal] command.
## Use together with [signal_name] property.
var inline: bool = false
## Only necessary if [inline] is true. Sets the argument to listen for.
var inline_signal_argument: String
## Only usefull if [inline] is true. If true, the command can only be used once. 
## If false it will not stop listening to the signal (with that argument).
var inline_single_use: bool = false


################################################################################
## 						EXECUTION
################################################################################

func _execute() -> void:
	if inline:
		dialogic.timeline_ended.connect(_disconnect_signal)
	
	if path.begins_with('root'):
		path = "/"+path
	if not "/" in path and dialogic.get_node('/root').has_node(path):
		path = "/root/"+path
	
	var n = dialogic.get_node_or_null(path)
	if n:
		if n.has_method(method):
			if inline:
				dialogic.text_signal.connect(_call_on_signal, CONNECT_PERSIST)
			elif wait:
				await n.callv(method, arguments).completed
			else:
				n.callv(method, arguments)
	
	finish()


func _call_on_signal(arg:String) -> void:
	if arg != inline_signal_argument:
		return
	if inline_single_use:
		dialogic.disconnect("text_signal", _call_on_signal)
	var n = dialogic.get_node_or_null(path)
	n.callv(method, arguments)


func _disconnect_signal():
	if dialogic.text_signal.is_connected(_call_on_signal):
		dialogic.text_signal.disconnect(_call_on_signal)


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Call Node"
	set_default_color('Color1')
	event_category = Category.Godot
	event_sorting_index = 3
	expand_by_default = false


################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "call_node"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_info
		"path" 		: {"property": "path", 		"default": ""},
		"method" 	: {"property": "method", 	"default": ""},
		"args" 		: {"property": "arguments", "default": []},
		"wait" 		: {"property": "wait", 		"default": false, 
						"suggestions": func(): return {'True':{'value':'true'}, 'False':{'value':'false'}}},
		"inline" 	: {"property": "inline", 	"default": false, 
						"suggestions": func(): return {'True':{'value':'true'}, 'False':{'value':'false'}}},
		"signal" 	: {"property": "inline_signal_argument", 	"default": ""},
		"single_use": {"property": "inline_single_use", 		"default": false, 
							"suggestions": func(): return {'True':{'value':'true'}, 'False':{'value':'false'}}}
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('method', ValueType.SinglelineText, 'Call method')
	add_header_edit('path', ValueType.SinglelineText, 'in object')
	add_body_edit('wait', ValueType.Bool, 'wait for method to finsih:')
	add_body_edit('inline', ValueType.Bool, 'Use as inline Command:')
	add_body_edit('inline_signal_argument', ValueType.SinglelineText, 'inline Signal Name', '', {}, 'inline == true')
	add_body_edit('inline_single_use', ValueType.Bool, 'Single Use:', '', {}, 'inline == true')
	add_body_line_break()
	add_body_edit('arguments', ValueType.StringArray, 'arguments:')
