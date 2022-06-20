tool
extends DialogicEvent


# DEFINE ALL PROPERTIES OF THE EVENT
var Timeline :DialogicTimeline = null
var Anchor : String = ""

func _execute() -> void:
	if Timeline:
		dialogic_game_handler.start_timeline(Timeline)
	else:
		finish()


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Change Timeline"
	event_color = Color("#12b76a")
	event_category = Category.TIMELINE
	event_sorting_index = 0
	


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "change_timeline"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"path"		: "Timeline",
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('Timeline', ValueType.Timeline, 'Timeline:')

