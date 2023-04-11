@tool
class_name DialogicHistoryEvent
extends DialogicEvent

## Event that allows clearing, pausing and resuming of history functionality.

enum ActionTypes {Clear, Pause, Resume}

### Settings

## The type of action: Clear, Pause or Resume
var action_type := ActionTypes.Pause


################################################################################
## 						EXECUTION
################################################################################

func _execute() -> void:
	match action_type:
		ActionTypes.Clear:
			dialogic.History.full_history = []
		ActionTypes.Pause:
			dialogic.History.full_history_enabled = false
		ActionTypes.Resume:
			dialogic.History.full_history_enabled = true
	
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "History"
	set_default_color('Color6')
	event_category = Category.Other
	event_sorting_index = 20
	expand_by_default = false


################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "history"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 		: property_info
		"action" 			: {"property": "action_type", "default": ActionTypes.Pause, 
								"suggestions": func(): return {"Clear":{'value':'0'}, "Pause":{'value':'1'}, "Resume":{'value':'2'}}},
	}

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('action_type', ValueType.FixedOptionSelector, '', '', {
		'selector_options': [
			{
				'label': 'Pause History',
				'value': ActionTypes.Pause,
			},
			{
				'label': 'Resume History',
				'value': ActionTypes.Resume,
			},
			{
				'label': 'Clear History',
				'value': ActionTypes.Clear,
			},
		]
		})
