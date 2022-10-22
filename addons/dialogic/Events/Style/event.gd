@tool
extends DialogicEvent
class_name DialogicStyleEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var StyleName: String = ""

func _execute() -> void:
	dialogic.Styles.change_style(StyleName)
	# base style isn't overridden by character styles
	# this means after a charcter style, we can change back to the base style
	dialogic.current_state_info['base_style'] = StyleName
	finish()


func get_required_subsystems() -> Array:
	return [
				{'name':'Styles',
				'subsystem': get_script().resource_path.get_base_dir().path_join('Subsystem_Styles.gd'),
				'character_main':get_script().resource_path.get_base_dir().path_join('CharacterEdit_Style.tscn')
				},
			]


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Change Style"
	set_default_color('Color4')
	event_category = Category.AUDIOVISUAL
	event_sorting_index = 4
	


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "style"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"name"		: "StyleName",
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('StyleName', ValueType.SinglelineText, 'Show all style nodes with name ', '(hides others)')
