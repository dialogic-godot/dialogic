@tool
extends DialogicEvent
class_name DialogicHistoryEvent

enum ActionTypes {Clear, Pause, Resume}

var ActionType := ActionTypes.Pause

func _execute() -> void:
	
	match ActionType:
		ActionTypes.Clear:
			dialogic.History.full_history = []
		ActionTypes.Pause:
			dialogic.History.full_history_enabled = false
		ActionTypes.Resume:
			dialogic.History.full_history_enabled = true
	
	finish()

func get_required_subsystems() -> Array:
	return [
				{'name':'History',
				'subsystem': get_script().resource_path.get_base_dir().path_join('Subsystem_History.gd'),
				'settings': get_script().resource_path.get_base_dir().path_join('SettingsEditor/Editor.tscn'),
				},
			]


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "History"
	set_default_color('Color6')
	event_category = Category.AUDIOVISUAL
	event_sorting_index = 0
	expand_by_default = false


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "history"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_name
		"action"			: "ActionType",
	}

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('ActionType', ValueType.FixedOptionSelector, '', '', {
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
