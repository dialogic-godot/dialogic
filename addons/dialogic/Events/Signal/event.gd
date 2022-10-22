@tool
extends DialogicEvent
class_name DialogicSignalEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var Argument: String = ""

func _execute() -> void:
	dialogic.emit_signal('signal_event', Argument)
	finish()


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Signal"
	set_default_color('Color1')
	event_category = Category.GODOT
	event_sorting_index = 0


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "signal"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"arg"		: "Argument",
	}

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('Argument', ValueType.SinglelineText, 'Emit "signal_event" signal with argument')
