@tool
extends DialogicEvent
class_name DialogicBackgroundEvent

# DEFINE ALL PROPERTIES OF THE EVENT
var Scene: String = ""
var Argument: String = ""
var Fade: float = 0.0

func _execute() -> void:
	dialogic.Backgrounds.update_background(Scene, Argument, Fade)
	finish()

func get_required_subsystems() -> Array:
	return [
				{'name':'Backgrounds',
				'subsystem':get_script().resource_path.get_base_dir().path_join('Subsystem_Backgrounds.gd')},
			]


################################################################################
## 						INITIALIZE
################################################################################

# SET ALL VALUES THAT SHOULD NEVER CHANGE HERE
func _init() -> void:
	event_name = "Background"
	set_default_color('Color4')
	event_category = Category.AUDIOVISUAL
	event_sorting_index = 0
	expand_by_default = false
	


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "background"

func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name : property_name
		"scene"		: "Scene",
		"arg"		: "Argument",
		"fade"		: "Fade"
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('Argument', ValueType.File, '', '', {'file_filter':'*.tscn, *.scn, *.jpg, *.jpeg, *.png, *.webp, *.tga, *svg, *.bmp, *.dds, *.exr, *.hdr', 'placeholder': "No background", 'editor_icon':["Image", "EditorIcons"]}, 'Scene == ""')
	add_header_edit('Argument', ValueType.SinglelineText, 'Argument:', '', {}, 'Scene != ""')
	add_body_edit("Fade", ValueType.Float, "Fade time: ")
	add_body_edit("Scene", ValueType.File, 'Scene:', '', {'file_filter':'*.tscn, *.scn','placeholder': "Default Scene", 'editor_icon':["PackedScene", "EditorIcons"]})
