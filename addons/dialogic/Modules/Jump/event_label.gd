@tool
class_name DialogicLabelEvent
extends DialogicEvent

## Event that is used as an anchor. You can use the DialogicJumpEvent to jump to this point.


### Settings

## Used to identify the label. Duplicate names in a timeline will mean it always chooses the first.
var name: String = ""


################################################################################
## 						EXECUTE
################################################################################

func _execute() -> void:
	# This event is mainly implemented in the DialogicGameHandlers jump_to_label() method.
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Label"
	set_default_color('Color3')
	event_category = "Timeline"
	event_sorting_index = 1
	continue_at_end = true


func _get_icon() -> Resource:
	return load(self.get_script().get_path().get_base_dir().path_join('icon_label.png'))


################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "label"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		"name" 			: {"property": "name", "default": ""},
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('name', ValueType.SinglelineText, '', '', {'autofocus':true})
