@tool
class_name DialogicBackgroundEvent
extends DialogicEvent

## Event to show scenes in the background and switch between them.

### Settings

## The scene to use. If empty, this will default to the DefaultBackground.gd scene.
## This scene supports images and fading.
## If you set it to a scene path, then that scene will be instanced.
## Learn more about custom backgrounds in the Subsystem_Background.gd docs.
var scene := ""
## The argument that is passed to the background scene.
## For the default scene it's the path to the image to show.
var argument := ""
## The time the fade animation will take. Leave at 0 for instant change.
var fade: float = 0.0
## Name of the transition to use.
var transition := ""
## If `true` will wait for the duration of the transition before continuing.
var await_transition := false

## Helpers for visual editor
enum ArgumentTypes {IMAGE, COLOR, STRING}
var _arg_type := ArgumentTypes.IMAGE:
	get:
		if argument.begins_with("res://"):
			return ArgumentTypes.IMAGE
		elif argument.begins_with("#") and argument.is_valid_html_color():
			return ArgumentTypes.COLOR
		elif argument.is_empty():
			return _arg_type
		else:
			return ArgumentTypes.STRING
	set(value):
		if value == ArgumentTypes.STRING:
			if not argument.begins_with(" "):
				argument = " "+argument
		elif value == ArgumentTypes.COLOR:
			if not (argument.is_valid_html_color() and argument.begins_with("#")):
				argument = "#"+Color.BLACK.to_html()
		elif value == ArgumentTypes.IMAGE:
			if not argument.begins_with(" res://"):
				argument = "res://"

		_arg_type = value

var _color_arg := Color():
	get():
		return Color.from_string(argument, Color.BLACK)
	set(c):
		_color_arg = c
		if _arg_type == ArgumentTypes.COLOR:
			argument = "#"+c.to_html()

enum SceneTypes {DEFAULT, CUSTOM}
var _scene_type := SceneTypes.DEFAULT :
	get:
		if scene.is_empty():
			return _scene_type
		else:
			return SceneTypes.CUSTOM
	set(value):
		if value == SceneTypes.DEFAULT:
			scene = ""
		_scene_type = value

#region EXECUTION
################################################################################

func _execute() -> void:
	var final_fade_duration := fade

	if dialogic.Inputs.auto_skip.enabled:
		var time_per_event: float = dialogic.Inputs.auto_skip.time_per_event
		final_fade_duration = min(fade, time_per_event)

	dialogic.Backgrounds.update_background(scene, argument, final_fade_duration, transition)

	if await_transition:
		await dialogic.get_tree().create_timer(final_fade_duration).timeout

	finish()

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Background"
	event_description = "Shows or hides a background image or scene."
	set_default_color('Color8')
	event_category = "Visuals"
	event_sorting_index = 0

#endregion


#region SAVE & LOAD
################################################################################

func get_shortcode() -> String:
	return "background"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		"scene" 		: {"property": "scene", 			"default": "", "ext_file":true},
		"arg" 			: {"property": "argument", 			"default": "", "ext_file":true},
		"fade" 			: {"property": "fade", 				"default": 0},
		"transition"	: {"property": "transition",		"default": "",
									"suggestions": get_transition_suggestions},
		"wait": 		{"property": "await_transition",	"default": false}
	}

#endregion


#region EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	add_header_edit('_scene_type', ValueType.FIXED_OPTIONS, {
		'left_text' :'Show',
		'options': [
			{
				'label': 'Background',
				'value': SceneTypes.DEFAULT,
				'icon': ["GuiRadioUnchecked", "EditorIcons"]
			},
			{
				'label': 'Scene',
				'value': SceneTypes.CUSTOM,
				'icon': ["PackedScene", "EditorIcons"]
			}
		]})
	#add_header_label("from file", "_scene_type == SceneTypes.DEFAULT")
	add_header_edit("scene", ValueType.FILE,
			{'file_filter':'*.tscn, *.scn; Scene Files',
			'placeholder': "Custom scene",
			'editor_icon': ["PackedScene", "EditorIcons"],
			}, '_scene_type == SceneTypes.CUSTOM')
	add_header_edit('_arg_type', ValueType.FIXED_OPTIONS, {
		'left_text' : 'with',
		'options': [
			{
				'label': 'Image',
				'value': ArgumentTypes.IMAGE,
				'icon': ["Image", "EditorIcons"]
			},
			{
				'label': 'Color',
				'value': ArgumentTypes.COLOR,
				'icon': ["Color", "EditorIcons"]
			},
			{
				'label': 'Argument',
				'value': ArgumentTypes.STRING,
				'icon': ["String", "EditorIcons"]
			}
		]})
	add_header_edit('argument', ValueType.FILE,
			{'file_filter':'*.jpg, *.jpeg, *.png, *.webp, *.tga, *svg, *.bmp, *.dds, *.exr, *.hdr; Supported Image Files',
			'placeholder': "No Image",
			'editor_icon': ["Image", "EditorIcons"],
			},
			'_arg_type == ArgumentTypes.IMAGE')
	add_header_edit('_color_arg', ValueType.COLOR, {}, '_arg_type == ArgumentTypes.COLOR')
	add_header_edit('argument', ValueType.SINGLELINE_TEXT, {}, '_arg_type == ArgumentTypes.STRING')

	add_body_edit("argument", ValueType.IMAGE_PREVIEW, {'left_text':'Preview:'},
		'(_arg_type == ArgumentTypes.IMAGE) and !argument.is_empty()')
	add_body_line_break('(_arg_type == ArgumentTypes.IMAGE) and !argument.is_empty()')

	add_body_edit("transition", ValueType.DYNAMIC_OPTIONS,
			{'left_text':'Transition:',
			'empty_text':'Simple Fade',
			'suggestions_func':get_transition_suggestions,
			'editor_icon':["PopupMenu", "EditorIcons"]})
	add_body_edit("fade", ValueType.NUMBER, {'left_text':'Fade time:'})
	add_body_edit("await_transition", ValueType.BOOL, {'left_text':'Await Fade:', "tooltip":"If true, will wait for the duration of the transition before continuing."})


func get_transition_suggestions(_filter:String="") -> Dictionary:
	var transitions := DialogicResourceUtil.list_special_resources("BackgroundTransition")
	var suggestions := {}
	for i in transitions:
		suggestions[DialogicUtil.pretty_name(i)] = {'value': DialogicUtil.pretty_name(i), 'editor_icon': ["PopupMenu", "EditorIcons"]}
	return suggestions

#endregion
