@tool
extends DialogicEvent
class_name DialogicScreenShakeEvent

## Event to shake the screen below the screen shake layer.

### Settings

enum Direction {HORIZONTAL, VERTICAL}

## The strength of the screen shake.
var amplitude: float = 0.1
## The speed of the screen shake.
var frequency: float = 1.0
## The direction of the screen shake.
var direction := Direction.HORIZONTAL
## The time the fade animation will take. Leave at 0 for instant change.
var fade: float = 0.0
## The time the screen should shake for (excludes fade time).
## Leave at 0 to keep shaking until the next screen shake event.
var duration: float = 10.0
## If true, the event will wait for completion before continuing
## (only if duration is greater than 0.0 or fade greater than 0.0 and amplitude is 0.0).
var wait := false

#region EXECUTION
################################################################################

func _execute() -> void:
	if direction == Direction.HORIZONTAL:
		dialogic.ScreenShake.update_shake_x(amplitude, frequency, fade, duration)

		if wait and (duration > 0.0 or (fade > 0.0 and amplitude == 0.0)):
			await dialogic.ScreenShake.shake_horizontal_finished
	else:
		dialogic.ScreenShake.update_shake_y(amplitude, frequency, fade, duration)

		if wait and (duration > 0.0 or (fade > 0.0 and amplitude == 0.0)):
			await dialogic.ScreenShake.shake_vertical_finished

	finish()

#endregion

#region INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Shake Screen"
	set_default_color('Color8')
	event_category = "Visuals"
	event_sorting_index = 2

#endregion

#region SAVING/LOADING
################################################################################

func get_shortcode() -> String:
	return "shake_screen"


func get_shortcode_parameters() -> Dictionary:
	return {
		"amplitude"			: {"property": "amplitude", "default": 0.1},
		"frequency"			: {"property": "frequency", "default": 1.0},
		"direction"			: {"property": "direction", "default": Direction.HORIZONTAL},
		"fade"				: {"property": "fade", "default": 0.0},
		"duration"			: {"property": "duration", "default": 10.0},
		"wait"				: {"property": "wait", "default": false},
	}

#endregion

#region EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	add_header_edit("direction", ValueType.FIXED_OPTIONS, {
		'left_text': 'Shake screen',
		'options': [
			{
				'label': 'Horizontally',
				'value': Direction.HORIZONTAL,
				'icon': ["MirrorX", "EditorIcons"]
			},
			{
				'label': 'Vertically',
				'value': Direction.VERTICAL,
				'icon': ["MirrorY", "EditorIcons"]
			}
		]})

	add_header_edit("amplitude", ValueType.NUMBER, {
		'left_text': 'with amplitude:',
		'min': 0.0,
		'max': 1.0,
		'step': 0.01,
	})

	add_header_edit("frequency", ValueType.NUMBER, {
		'left_text': 'and frequency:',
		'min': 0.1,
		'suffix': 'hz',
	})

	add_body_edit("fade", ValueType.NUMBER, {'left_text':'Fade time:'})
	add_body_edit("duration", ValueType.NUMBER, {'left_text': 'Duration:'}, 'amplitude > 0.0')
	add_body_edit("wait", ValueType.BOOL, {'left_text':'Wait for completion:'}, '(fade > 0.0 and amplitude == 0.0) or duration > 0.0')

#endregion
