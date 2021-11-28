extends TextureRect

## Update for inclusivness
## small addition to make dialogic usable without pressing any keys
## Simulate input after some focus time

onready var next_timer = $NextTimer

var hovering_mode = false ## checks if hovering_mode mode is on
var focus_time = 2 ## time before input gets sent
var success = false ## checks for focus

func set_hovering_mode(mode: bool) -> void:
	hovering_mode = mode

func _on_NextIndicator_mouse_entered():
	if hovering_mode:
		success = true
		next_timer.start(focus_time)

func _on_NextIndicator_mouse_exited():
	if hovering_mode:
		success = false
		next_timer.stop()

func _on_NextTimer_timeout():
	if success:
		success = false
		simulate_input()

func simulate_input():
	var ev = InputEventAction.new()
	ev.action = Dialogic.get_action_button()
	ev.pressed = true
	get_tree().input_event(ev)
