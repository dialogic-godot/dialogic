extends Button

## Update for inclusivness
## small addition to make dialogic usable without pressing any keys
## Simulate input after some focus time

onready var next_timer = $NextTimer

var hovering_mode = false
var focus_time = 2 ## time before input gets sent
var success = false ## checks for focus

func set_hovering_mode(mode: bool) -> void:
	hovering_mode = mode

func _on_ChoiceButton_mouse_entered():
	if hovering_mode:
		success = true
		next_timer.start(focus_time)

func _on_ChoiceButton_mouse_exited():
	if hovering_mode:
		success = false
		next_timer.stop()

func _on_NextTimer_timeout():
	if success:
		success = false
		simulate_input()

func simulate_input():
	emit_signal("button_down")
	emit_signal("button_up")
	emit_signal("pressed")

func _process(delta):
	if has_focus():
		if Input.is_action_pressed(get_meta('input_next')):
			emit_signal("button_down")
		if Input.is_action_just_released(get_meta('input_next')):
			emit_signal("button_up")
			emit_signal("pressed")
