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
	var final_fade_duration := fade

	if Dialogic.Input.auto_skip.enabled:
		var time_per_event: float = Dialogic.Input.auto_skip.time_per_event
		final_fade_duration = min(fade, time_per_event)

	dialogic.Backgrounds.update_background(scene, argument, final_fade_duration)
	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Background"
	set_default_color('Color8')
	event_category = "Visuals"
	event_sorting_index = 0


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
	add_header_edit('argument', ValueType.FILE,
			{'left_text' : 'Show',
			'file_filter':'*.jpg, *.jpeg, *.png, *.webp, *.tga, *svg, *.bmp, *.dds, *.exr, *.hdr; Supported Image Files',
			'placeholder': "No background",
			'editor_icon':["Image", "EditorIcons"]},
			'scene == ""')
	add_header_edit('argument', ValueType.SINGLELINE_TEXT, {'left_text':'Argument:'}, 'scene != ""')
	add_body_edit("fade", ValueType.FLOAT, {'left_text':'Fade Time:'})
	add_body_edit("scene", ValueType.FILE,
			{'left_text' :'Scene:',
			'file_filter':'*.tscn, *.scn; Scene Files',
			'placeholder': "Default scene",
			'editor_icon':["PackedScene", "EditorIcons"]})
