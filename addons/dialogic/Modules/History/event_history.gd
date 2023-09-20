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
			dialogic.History.full_history = []
		Actions.PAUSE:
			dialogic.History.full_history_enabled = false
		Actions.RESUME:
			dialogic.History.full_history_enabled = true
	
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
								"suggestions": func(): return {"Clear":{'value':0}, "Pause":{'value':1}, "Resume":{'value':2}}},
	}

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('action', ValueType.FIXED_OPTION_SELECTOR, {
		'selector_options': [
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
