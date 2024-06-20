@tool
class_name DialogicPositionEvent
extends DialogicEvent

## Event that allows moving of positions (and characters that are on that position).
## Requires the Portraits subsystem to be present!

enum Actions {CHANGE, RESET, RESET_ALL}


### Settings

## The type of action: SetRelative, SetAbsolute, Reset, ResetAll
var action := Actions.CHANGE
## The position that should be affected
var position: String = "center"

var relative_change := false

## A string containing the position
## This string can contain x and y component: "x100 y200".
## Each component can be a percentage: "x.5% y1%"
var translation := ""
var set_translation := false # auto-set

var rotation: float = 0
var set_rotation := false # auto-set

## A string
var rect_size := ""
var set_rect_size := false # auto-set

var scale: Vector2 = Vector2()
var set_scale := false # auto-set

## The time the tweening will take.
var tween_time: float = 0.5

var tween_ease := Tween.EaseType.EASE_IN_OUT
var tween_trans := Tween.TransitionType.TRANS_SINE

var tween_await := true

var ease_options := [
		{'label': 'In', 	 'value': Tween.EASE_IN},
		{'label': 'Out', 	 'value': Tween.EASE_OUT},
		{'label': 'In_Out', 'value': Tween.EASE_IN_OUT},
		{'label': 'Out_In', 'value': Tween.EASE_OUT_IN},
		]

var trans_options := [
		{'label': 'Linear', 	'value': Tween.TRANS_LINEAR},
		{'label': 'Sine', 		'value': Tween.TRANS_SINE},
		{'label': 'Quint', 		'value': Tween.TRANS_QUINT},
		{'label': 'Quart', 		'value': Tween.TRANS_QUART},
		{'label': 'Quad', 		'value': Tween.TRANS_QUAD},
		{'label': 'Expo', 		'value': Tween.TRANS_EXPO},
		{'label': 'Elastic', 	'value': Tween.TRANS_ELASTIC},
		{'label': 'Cubic', 		'value': Tween.TRANS_CUBIC},
		{'label': 'Circ', 		'value': Tween.TRANS_CIRC},
		{'label': 'Bounce', 	'value': Tween.TRANS_BOUNCE},
		{'label': 'Back', 		'value': Tween.TRANS_BACK},
		{'label': 'Spring', 	'value': Tween.TRANS_SPRING}
		]


################################################################################
## 						EXECUTE
################################################################################
func _execute() -> void:
	var final_movement_time: float = tween_time

	if dialogic.Inputs.auto_skip.enabled:
		var time_per_event: float = dialogic.Inputs.auto_skip.time_per_event
		final_movement_time = max(tween_time, time_per_event)

	var container: DialogicNode_PortraitContainer = dialogic.PortraitContainers.get_container(position)
	match action:
		Actions.RESET_ALL:
			var tween := dialogic.create_tween().set_parallel(true).set_ease(tween_ease).set_trans(tween_trans)
			dialogic.PortraitContainers.reset_all_containers(final_movement_time, tween)
			if tween_await and tween.is_running():
				await tween.finished
		Actions.RESET:
			if container:
				var tween := dialogic.create_tween().set_parallel(true).set_ease(tween_ease).set_trans(tween_trans)
				dialogic.PortraitContainers.reset_container(container, final_movement_time, tween)
				if tween_await and tween.is_running():
					await tween.finished
		Actions.CHANGE:
			if container == null:
				container = dialogic.PortraitContainers.add_container(position, translation, rect_size)

			var tween := dialogic.create_tween().set_parallel(true).set_ease(tween_ease).set_trans(tween_trans)
			if set_translation:
				dialogic.PortraitContainers.translate_container(container, translation, relative_change, tween, tween_time)
			if set_rotation:
				dialogic.PortraitContainers.rotate_container(container, rotation, relative_change, tween, tween_time)
			if set_rect_size:
				dialogic.PortraitContainers.resize_container(container, rect_size, relative_change, tween, tween_time)

			if tween_await and tween.is_running():
				await tween.finished


	finish()


################################################################################
## 						INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Position"
	set_default_color('Color2')
	event_category = "Other"
	event_sorting_index = 2


func _get_icon() -> Resource:
	return load(self.get_script().get_path().get_base_dir().path_join('event_portrait_position.svg'))

################################################################################
## 						SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "update_position"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		"action"		: {"property": "action", 		"default": Actions.CHANGE,
								"suggestions": func(): return {"Change":{'value':0, 'text_alt':['change', 'set']}, "Reset":{'value':1,'text_alt':['reset'] }, "Reset All":{'value':2,'text_alt':['reset_all']}}},
		"id" 		: {"property": "position", 			"default": "0"},
		"pos" 		: {"property": "translation", 		"default": ""},
		"rot" 		: {"property": "rotation", 		"default": 0},
		"size" 		: {"property": "rect_size", 		"default": Vector2()},
		"relative" 	: {"property":"relative_change",	"default": false},
		"time" 	:  {"property": "tween_time", 	"default": 0},
		"await" :  {"property": "tween_await", 	"default": true},
		"ease" 	:  {"property": "tween_ease", 	"default": Tween.EaseType.EASE_IN_OUT,
								"suggestions": func(): return list_to_suggestions(ease_options)},
		"trans"	:  {"property": "tween_trans", 	"default": Tween.TransitionType.TRANS_SINE,
								"suggestions": func(): return list_to_suggestions(trans_options)},
	}


################################################################################
## 						EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	add_header_edit('action', ValueType.FIXED_OPTIONS, {
		'options': [
			{
				'label': 'Change',
				'value': Actions.CHANGE,
			},
			{
				'label': 'Reset',
				'value': Actions.RESET,
			},
			{
				'label': 'Reset All',
				'value': Actions.RESET_ALL,
			}
		]
		})
	add_header_edit("position", ValueType.DYNAMIC_OPTIONS, {
			'suggestions_func':get_position_suggestions,
			'placeholder': "Position"},
			'action != Actions.RESET_ALL',
			)
	add_body_edit('set_translation', ValueType.BOOL_BUTTON,
			{'editor_icon': ["ToolMove", "EditorIcons"], 'tooltip':'Change translation'}, "action == Actions.CHANGE")
	add_body_edit("translation", ValueType.SINGLELINE_TEXT, {'left_text':'Translate:'},
			"action == Actions.CHANGE and set_translation")
	add_body_edit('set_rotation', ValueType.BOOL_BUTTON,
			{'editor_icon': ["ToolRotate", "EditorIcons"], 'tooltip':'Change Rotation'}, "action == Actions.CHANGE")
	add_body_edit("rotation", ValueType.NUMBER, {'left_text':'Rotate:', 'min':-360, 'max':360},
			"action == Actions.CHANGE and set_rotation")
	add_body_edit('set_rect_size', ValueType.BOOL_BUTTON,
		{'editor_icon': ["Rectangle", "EditorIcons"], 'tooltip':'Change Rect Size'}, "action == Actions.CHANGE")
	add_body_edit("rect_size", ValueType.SINGLELINE_TEXT, {'left_text':'Rect Size:'},
			"action == Actions.CHANGE and set_rect_size")
	add_body_edit("relative_change", ValueType.BOOL, {'left_text':"Relative:"}, "action == Actions.CHANGE")
	add_body_line_break("action == Actions.CHANGE")
	add_body_edit("tween_time", ValueType.NUMBER, {'left_text':"Time:"})
	add_body_edit("tween_await", ValueType.BOOL, {'left_text':"Await:"}, 'tween_time > 0')
	add_body_edit("tween_trans", ValueType.FIXED_OPTIONS, {'options':trans_options, 'left_text':"Trans:"}, 'tween_time > 0')
	add_body_edit("tween_ease", ValueType.FIXED_OPTIONS, {'options':ease_options, 'left_text':"Ease:"}, 'tween_time > 0')


func list_to_suggestions(list:Array) -> Dictionary:
	return list.reduce(
		func(accum, value):
			accum[value.label] = value
			accum[value.label]["text_alt"] = [value.label.to_lower()]
			return accum,
		{})


func get_position_suggestions(search_text:String='') -> Dictionary:
	var icon := load(this_folder.path_join('event_portrait_position.svg'))
	var setting: String = ProjectSettings.get_setting('dialogic/portraits/position_suggestion_names', 'leftmost, left, center, right, rightmost')

	var suggestions := {}
	if not search_text.is_empty():
		suggestions[search_text] = {'value':search_text.strip_edges(), 'editor_icon':["GuiScrollArrowRight", "EditorIcons"]}
	for position_id in setting.split(','):
		suggestions[position_id.strip_edges()] = {'value':position_id.strip_edges(), 'icon':icon}
		if not search_text.is_empty() and position_id.strip_edges().begins_with(search_text):
			suggestions.erase(search_text)
	return suggestions
