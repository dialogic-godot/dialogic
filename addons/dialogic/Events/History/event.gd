@tool
extends DialogicEvent
class_name DialogicHistoryEvent

func _execute() -> void:
	pass

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
	}

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	pass
