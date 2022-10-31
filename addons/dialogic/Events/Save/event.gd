@tool
extends DialogicEvent
class_name DialogicSaveEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var SlotName :String = "Default"

func _execute() -> void:
	if SlotName:
		dialogic.Save.save(SlotName)
	finish()

func get_required_subsystems() -> Array:
	return [
				{'name':'Save', 
				'subsystem': get_script().resource_path.get_base_dir().path_join('Subsystem_Save.gd'),
				'settings': get_script().resource_path.get_base_dir().path_join('Settings_Saving.tscn')},
			]

################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Save"
	set_default_color('Color2')
	event_category = Category.MAIN
	event_sorting_index = 2


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "save"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"slot"		: "SlotName",
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('SlotName', ValueType.SinglelineText, 'to slot')
