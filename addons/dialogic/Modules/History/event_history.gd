@tool
class_name DialogicHistoryEvent
extends DialogicEvent

## Event that allows clearing, pausing and resuming of history functionality.

enum Actions {CLEAR, PAUSE, RESUME}

### Settings

## The type of action: Clear, Pause or Resume
var action := Actions.PAUSE


################################################################################
## 						EXECUTION
################################################################################

func _execute() -> void:
	match action:
		Actions.CLEAR:
			dialogic.History.simple_history_content = []
		Actions.PAUSE:
			dialogic.History.simple_history_enabled = false
		Actions.RESUME:
			dialogic.History.simple_history_enabled = true

	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "History"
	set_default_color('Color9')
	event_category = "Other"
	event_sorting_index = 20


################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "history"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 		: property_info
		"action" 			: {"property": "action", "default": Actions.PAUSE,
								"suggestions": func(): return {"Clear":{'value':0, 'text_alt':['clear']}, "Pause":{'value':1, 'text_alt':['pause']}, "Resume":{'value':2, 'text_alt':['resume', 'start']}}},
	}

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	add_header_edit('action', ValueType.FIXED_OPTIONS, {
		'options': [
			{
				'label': 'Pause History',
				'value': Actions.PAUSE,
			},
			{
				'label': 'Resume History',
				'value': Actions.RESUME,
			},
			{
				'label': 'Clear History',
				'value': Actions.CLEAR,
			},
		]
		})
