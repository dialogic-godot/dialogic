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
var wipe_texture_path: String = ""
## The size of the smear behine the whipe.
var feather: float = 0.0
## Determines if the whipe texture should keep the aspect ratio when scaled to the screen size.
var keep_aspect_ratio: bool = false

## The custom shader used for transitions.
var custom_shader_path: String = ""
## The shader parameter overrides to selectively change arguments of a shader.
var shader_parameter_overrides: Dictionary = {}

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
	
	var shader_material: ShaderMaterial = null
	if !custom_shader_path.is_empty():
		var shader_resource = load(custom_shader_path)
		var shader: Shader
		
		if shader_resource is ShaderMaterial:
			shader_material = shader_resource
			shader = shader_material.shader
		#elif shader_resource is Shader:
		#	shader = shader_resource
		#	shader_material = ShaderMaterial.new()
		#	shader_material.shader = shader
		else:
			push_error("[Dialogic] Could not load shader or shader material: '", shader_resource, "'")
			finish()
		
		# filter out uniforms that are managed by Dialogic
		var uniforms = shader.get_shader_uniform_list().filter(func (entry: Dictionary) -> bool: 
			return entry["name"] == "progress" || entry["name"] == "previous_background" || entry["name"] == "next_background"
		)
		
		# TODO: do more validation in regards to typing of overrides?
		
		
	elif !wipe_texture_path.is_empty():
		var wipe_texture = load(wipe_texture_path) as Texture2D
		if wipe_texture == null:
			push_error("[Dialogic] Could not load whipe texture: '",wipe_texture_path,"'")
			finish()
		
		shader_arguments["wipe_texture"] = wipe_texture
		shader_arguments["feather"] = feather
		shader_arguments["keep_aspect_ratio"] = keep_aspect_ratio
	
	dialogic.Backgrounds.update_background(scene, argument, final_fade_duration, shader_material, shader_arguments)
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
		"scene" 		: {"property": "scene", 						"default": ""},
		"arg" 			: {"property": "argument", 						"default": ""},
		"fade" 			: {"property": "fade", 							"default": 0},
		"wipe" 			: {"property": "wipe_texture_path",				"default": ""},
		"feather" 		: {"property": "feather", 						"default": 0.0},
		"keep_ratio" 	: {"property": "keep_aspect_ratio",				"default": false},
		"shader" 		: {"property": "custom_shader_path",			"default": ""},
		"overrides"		: {"property": "shader_parameter_overrides",	"default": {}}
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
	
	add_body_edit("custom_shader_path", ValueType.FILE,
			{
				'left_text'		: 'Custom Shader:',
				'file_filter'	: '*.tres, *.res, *.material, *.gdshader; Supported Shader Files',
				'placeholder'	: "Default shader",
				'tooltip'		: "The path to the shader, can either be a shader material or shader core/graph file.",
				'editor_icon'	:["Shader", "EditorIcons"]
			})
	#add_body_edit('shader_parameter_overrides', ValueType.KEY_VALUE_PAIRS, {'left_text': 'Shader overrides'},'custom_shader_path != ""')
	
	add_body_edit("wipe_texture_path", ValueType.FILE,
			{
				'left_text'		: 'Whipe texture:',
				'file_filter'	: '*.jpg, *.jpeg, *.png, *.webp, *.tga, *svg, *.bmp, *.dds, *.exr, *.hdr; Supported Image Files',
				'placeholder'	: "No wipe",
				'editor_icon'	:["Image", "EditorIcons"]
			}, 'custom_shader_path == ""')
	add_body_edit("feather", ValueType.FLOAT, {'left_text':'Whipe Feather:', 'max': 1}, 'wipe_texture_path != "" && custom_shader_path == ""')
	add_body_edit("keep_aspect_ratio", ValueType.BOOL, {'left_text':'Keep Aspect Ratio:'}, 'wipe_texture_path != "" && custom_shader_path == ""')
