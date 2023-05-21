@tool
class_name DialogicGlossaryEvent
extends DialogicEvent

## Event that does nothing right now.


################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	pass


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Glossary"
	set_default_color('Color6')
	event_category = "Other"
	event_sorting_index = 0
	expand_by_default = false


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "glossary"

func get_shortcode_parameters() -> Dictionary:
	return {
	}

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	pass
