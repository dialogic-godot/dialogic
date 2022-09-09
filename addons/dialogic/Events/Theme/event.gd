@tool
extends DialogicEvent
class_name DialogicChangeThemeEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var ThemeName: String = ""

func _execute() -> void:
	dialogic.Themes.change_theme(ThemeName)
	# base theme isn't overridden by character themes
	# these means after a charcter theme, we can change back to the base theme
	dialogic.current_state_info['base_theme'] = ThemeName
	finish()


func get_required_subsystems() -> Array:
	return [
				{'name':'Themes',
				'subsystem': get_script().resource_path.get_base_dir().path_join('Subsystem_Themes.gd'),
				'character_main':get_script().resource_path.get_base_dir().path_join('Theme_CharacterEdit.tscn')
				},
			]


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Change Theme"
	set_default_color('Color4')
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
