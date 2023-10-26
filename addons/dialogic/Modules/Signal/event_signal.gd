@tool
class_name DialogicSignalEvent
extends DialogicEvent

## Event that emits the Dialogic.signal_event signal with an argument.
## You can connect to this signal like this: `Dialogic.signal_event.connect(myfunc)`


### Settings

var dictionaryMode : bool = false

## The argument that will be provided with the signal.
var argument: Variant = ""

################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:	
	if dictionaryMode:
		var result = JSON.parse_string(argument) 
		if result != null:
			var dict := result as Dictionary
			dict.make_read_only()
			dialogic.emit_signal('signal_event', dict)
		else:
			push_error("encountered malformed dictionary in signal")
	else:
		dialogic.emit_signal('signal_event', argument)
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Signal"
	set_default_color('Color6')
	event_category = "Logic"
	event_sorting_index = 8


################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "signal"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_info
		"dictMode"	: {"property": "dictionaryMode", "default": false},
		"arg"		: {"property": "argument", "default": ""}
	}

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_label("Emit with argument type:")
	add_header_edit('dictionaryMode',ValueType.BOOL, {'left_text':'string', 'right_text': 'dictionary', 'autofocus':true})
	add_body_edit('argument', ValueType.KEY_VALUE_PAIRS, {'left_text': 'Emit with dictionary'},'dictionaryMode')
	add_body_edit('argument', ValueType.SINGLELINE_TEXT, {'left_text':'Emit with argument'}, '!dictionaryMode')
