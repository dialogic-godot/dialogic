@tool
class_name DialogicStyleEvent
extends DialogicEvent

## Event that allows changing the currently displayed style.


### Settings

## The name of the style to change to. Can be set on the DialogicNode_Style. 
var style_name: String = ""


################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	dialogic.Styles.change_style(style_name)
	# base style isn't overridden by character styles
	# this means after a charcter style, we can change back to the base style
	dialogic.current_state_info['base_style'] = style_name
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Change Style"
	set_default_color('Color4')
	event_category = "Other"
	event_sorting_index = 1


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "style"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_info
		"name" 		: {"property": "style_name", "default": ""},
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('style_name', ValueType.SinglelineText, 'Show all style nodes with name ', '(hides others)')
