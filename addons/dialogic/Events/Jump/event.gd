tool
extends DialogicEvent
class_name DialogicJumpEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var Timeline :DialogicTimeline = null
var Label : String = ""

func _execute() -> void:
	if Timeline and Timeline != dialogic.current_timeline:
		#print("---------------switching timelines----------------")
		dialogic.start_timeline(Timeline, Label)
	elif Label:
		dialogic.jump_to_label(Label)
	finish()


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Jump"
	set_default_color('Color2')
	event_category = Category.TIMELINE
	event_sorting_index = 0
	


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "jump"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"timeline"		: "Timeline",
		"label"		: "Label",
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('Timeline', ValueType.ComplexPicker, 'Timeline:', '', {'file_extension':'.dtl', 'icon':load("res://addons/dialogic/Editor/Images/Resources/timeline.svg")})
	add_header_edit('Label', ValueType.SinglelineText, 'Label:')

