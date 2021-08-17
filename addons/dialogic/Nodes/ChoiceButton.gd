extends Button

func _process(delta):
	if has_focus():
		if Input.is_action_pressed(get_meta('input_next')):
			emit_signal("button_down")
		if Input.is_action_just_released(get_meta('input_next')):
			emit_signal("button_up")
			emit_signal("pressed")
