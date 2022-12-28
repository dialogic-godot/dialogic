@tool
class_name DialogicSaveEvent
extends DialogicEvent

## Event that allows saving to a specific slot.


### Settings

## The name of the slot to save to. Learn more in the saving subsystem.
## If empty, the event will attempt to save to the latest slot, and otherwise use the default.
var slot_name: String = ""


################################################################################
## 						INITIALIZE
################################################################################

func _execute() -> void:
	if slot_name.is_empty():
		if Dialogic.Save.get_latest_slot():
			dialogic.Save.save(Dialogic.Save.get_latest_slot())
		else:
			dialogic.Save.save()
	else:
		dialogic.Save.save(slot_name)
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Save"
	set_default_color('Color2')
	event_category = Category.Main
	event_sorting_index = 2


################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "save"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_info
		"slot"		: {"property": "slot_name", "default": "Default"},
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('slot_name', ValueType.SinglelineText, 'to slot')
