extends "res://addons/dialogic/Modules/Background/Transitions/simple_push_transitions.gd"

func _fade() -> void:
	var shader := setup_push_shader()
	shader.set_shader_parameter('final_offset', Vector2.UP)
	tween_shader_progress().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

