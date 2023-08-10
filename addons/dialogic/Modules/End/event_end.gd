@tool
class_name DialogicEndTimelineEvent
extends DialogicEvent

## Event that ends a timeline (even if more events come after).


################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	for character in dialogic.Portraits.get_joined_characters():
		dialogic.Portraits.remove_character(character)
	dialogic.end_timeline()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "End"
	set_default_color('Color4')
	event_category = "Flow"
	event_sorting_index = 10


################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "end_timeline"

################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_label('End Timeline')
