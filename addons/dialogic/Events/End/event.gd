tool
extends DialogicEvent
class_name DialogicEndTimelineEvent

# DEFINE ALL PROPERTIES OF THE EVENT


func _execute() -> void:
	for character in dialogic_game_handler.get_joined_characters():
		dialogic_game_handler.remove_portrait(character)
	dialogic_game_handler.end_timeline()


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "End Timeline"
	event_color = Color("#f04438")
	event_category = Category.TIMELINE
	event_sorting_index = 10
	


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "end_timeline"
