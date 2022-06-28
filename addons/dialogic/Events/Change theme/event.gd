tool
extends DialogicEvent
class_name DialogicChangeThemeEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var ThemeName: String = ""

func _execute() -> void:
	dialogic_game_handler.change_theme(ThemeName)
	# base theme isn't overridden by character themes
	# these means after a charcter theme, we can change back to the base theme
	dialogic_game_handler.set_current_state_info('base_theme', ThemeName)
	finish()


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Change Theme"
	event_color = Color("#f63d67")
	event_category = Category.AUDIOVISUAL
	event_sorting_index = 4
	


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "theme"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"name"		: "ThemeName",
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('ThemeName', ValueType.SinglelineText, 'Name:')
