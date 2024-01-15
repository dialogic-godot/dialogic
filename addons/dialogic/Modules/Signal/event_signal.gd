@tool
class_name DialogicSignalEvent
extends DialogicEvent

## Event that emits the Dialogic.signal_event signal with an argument.
## You can connect to this signal like this: `Dialogic.signal_event.connect(myfunc)`


### Settings

enum ArgumentTypes {STRING, DICTIONARY}
var argument_type := ArgumentTypes.STRING

## The argument that will be provided with the signal.
var argument: Variant = ""

################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	if argument_type == ArgumentTypes.DICTIONARY:
		var result: Variant = JSON.parse_string(argument)
		if result != null:
			var dict := result as Dictionary
			dict.make_read_only()
			dialogic.emit_signal('signal_event', dict)
		else:
			push_error("[Dialogic] Encountered invalid dictionary in signal event.")
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
		"arg_type"	: {"property": "argument_type", "default": ArgumentTypes.STRING,
										"suggestions": func(): return {"String":{'value':ArgumentTypes.STRING, 'text_alt':['string']}, "Dictionary":{'value':ArgumentTypes.DICTIONARY, 'text_alt':['dict', 'dictionary']}}},
		"arg"		: {"property": "argument", "default": ""}
	}

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_label("Emit dialogic signal with argument")
	add_header_label("(Dictionary in body)", 'argument_type == ArgumentTypes.DICTIONARY')
	add_header_edit('argument', ValueType.SINGLELINE_TEXT, {}, 'argument_type == ArgumentTypes.STRING')
	add_body_edit('argument_type',ValueType.FIXED_OPTIONS, {'left_text':'Argument Type:', 'options': [
			{
				'label': 'String',
				'value': ArgumentTypes.STRING,
			},
			{
				'label': 'Dictionary',
				'value': ArgumentTypes.DICTIONARY,
			}
		]})
	add_body_line_break('argument_type == ArgumentTypes.DICTIONARY')
	add_body_edit('argument', ValueType.DICTIONARY, {'left_text': 'Dictionary'},'argument_type == ArgumentTypes.DICTIONARY')
