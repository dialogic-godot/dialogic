@tool
extends DialogicEvent
class_name DialogicEndTimelineEvent

# DEFINE ALL PROPERTIES OF THE EVENT


func _execute() -> void:
	for character in dialogic.Portraits.get_joined_characters():
		dialogic.Portraits.remove_portrait(character)
	dialogic.end_timeline()


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "End Timeline"
	set_default_color('Color4')
	event_category = Category.TIMELINE
	event_sorting_index = 10
	


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "end_timeline"
