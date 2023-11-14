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

## The whipe texture used for a custom whipe.
var whipe_texture_path: String = ""
## The size of the smear behine the whipe.
var feather: float = 0.0
## Determines if the whipe texture should keep the aspect ratio when scaled to the screen size.
var keep_aspect_ratio: bool = false

################################################################################
## 						EXECUTION
################################################################################

func _execute() -> void:
	var final_fade_duration := fade

	if Dialogic.Input.auto_skip.enabled:
		var time_per_event: float = Dialogic.Input.auto_skip.time_per_event
		final_fade_duration = min(fade, time_per_event)
	
	# add arguments for custom whipe
	var shader_arguments = Dictionary()
	if !whipe_texture_path.is_empty():
		var whipe_texture = load(whipe_texture_path) as Texture2D
		if whipe_texture == null:
			push_error("[Dialogic] Could not load whipe texture: '",whipe_texture_path,"'")
			finish()
		
		shader_arguments["whipe_texture"] = whipe_texture
		shader_arguments["feather"] = feather
		shader_arguments["keep_aspect_ratio"] = keep_aspect_ratio

	dialogic.Backgrounds.update_background(scene, argument, final_fade_duration, shader_arguments)
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
		"scene" 		: {"property": "scene", 				"default": ""},
		"arg" 			: {"property": "argument", 				"default": ""},
		"fade" 			: {"property": "fade", 					"default": 0},
		"whipe" 		: {"property": "whipe_texture_path",	"default": ""},
		"feather" 		: {"property": "feather", 				"default": 0.0},
		"keep_ratio" 	: {"property": "keep_aspect_ratio",		"default": false},
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
	add_body_edit("whipe_texture_path", ValueType.FILE,
			{
				'left_text'		: 'Whipe texture:',
				'file_filter'	: '*.tres, *.res, *.bmp, *.dds, *.exr, *.hdr, *.jpg, *.jepg, *.png, *.tga, *.svg, *.svgz, *.webp',
				'placeholder'	: "No whipe",
				'editor_icon'	:["Image", "EditorIcons"]
			})
	add_body_edit("feather", ValueType.FLOAT, {'left_text':'Whipe Feather:', 'max': 1}, 'whipe_texture_path != ""')
	add_body_edit("keep_aspect_ratio", ValueType.BOOL, {'left_text':'Keep Aspect Ratio:'}, 'whipe_texture_path != ""')
