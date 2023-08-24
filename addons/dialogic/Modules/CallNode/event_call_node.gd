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
var inline_single_use: bool = true


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
	
	var n :Node = dialogic.get_node_or_null(path)
	if n:
		if n.has_method(method):
			if inline:
				dialogic.text_signal.connect(_call_on_signal, CONNECT_PERSIST)
			elif wait:
				dialogic.current_state = dialogic.States.WAITING
				await n.callv(method, arguments)
				dialogic.current_state = dialogic.States.IDLE
			else:
				n.callv(method, arguments)
	else:
		printerr('[Dialogic] Call node event failed because of invalid path.')
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
	set_default_color('Color6')
	event_category = "Logic"
	event_sorting_index = 10
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
		"wait" 		: {"property": "wait", 		"default": false},
		"inline" 	: {"property": "inline", 	"default": false},
		"signal" 	: {"property": "inline_signal_argument", 	"default": ""},
		"single_use": {"property": "inline_single_use", 		"default": false}
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('method', ValueType.SINGLELINE_TEXT, 'Call method')
	add_header_edit('path', ValueType.SINGLELINE_TEXT, 'in object')
	add_body_edit('inline', ValueType.BOOL, 'Inline Command:', '', {'tooltip':"If enabled, the method won't be called instantly. Only when a signal is emmited inside the following text event will it be called."})
	add_body_edit('inline_signal_argument', ValueType.SINGLELINE_TEXT, 'Inline Signal Argument', '', {'tooltip':"For example if set to 'Hello' the method can be called with [signal=Hello] in the next text event."}, 'inline == true')
	add_body_edit('inline_single_use', ValueType.BOOL, 'Single Use:', '', {'tooltip':"By default calling via in-text signal only works once. Uncheck this to make the event keep listening. \nThis only stays valid during this dialog."}, 'inline == true')
	add_body_edit('wait', ValueType.BOOL, 'Wait:', '', {'tooltip':'Will wait for the method to finish. Only relevant for methods with `await` in them.'}, 'inline == false')
	add_body_line_break()
	add_body_edit('arguments', ValueType.STRING_ARRAY, 'Arguments:')
