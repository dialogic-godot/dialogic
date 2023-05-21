@tool
class_name DialogicBackgroundEvent
extends DialogicEvent

## Event to show scenes in the background and switch between them. 

### Settings

## The scene to use. If empty, this will default to the DefaultBackground.gd scene.
## This scene supports images and fading.
## If you set it to a scene path, then that scene will be instanced.
## Learn more about custom backgrounds in the Subsystem_Background.gd docs.
var scene: String = ""
## The argument that is passed to the background scene. 
## For the default scene it's the path to the image to show.
var argument: String = ""
## The time the fade animation will take. Leave at 0 for instant change.
var fade: float = 0.0


################################################################################
## 						EXECUTION
################################################################################

func _execute() -> void:
	dialogic.Backgrounds.update_background(scene, argument, fade)
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Background"
	set_default_color('Color4')
	event_category = "Other"
	event_sorting_index = 0
	expand_by_default = false


################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "background"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		"scene" 		: {"property": "scene", 	"default": ""},
		"arg" 			: {"property": "argument", 	"default": ""},
		"fade" 			: {"property": "fade", 		"default": 0},
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor():
	add_header_edit('argument', ValueType.File, '', '', 
			{'file_filter':'*.jpg, *.jpeg, *.png, *.webp, *.tga, *svg, *.bmp, *.dds, *.exr, *.hdr; Supported Image Files', 
			'placeholder': "No background", 
			'editor_icon':["Image", "EditorIcons"]}, 
			'scene == ""')
	add_header_edit('argument', ValueType.SinglelineText, 'Argument:', '', {}, 'scene != ""')
	add_body_edit("fade", ValueType.Float, "Fade Time: ")
	add_body_edit("scene", ValueType.File, 'Scene:', '', 
			{'file_filter':'*.tscn, *.scn; Scene Files',
			'placeholder': "Default scene", 
			'editor_icon':["PackedScene", "EditorIcons"]})
