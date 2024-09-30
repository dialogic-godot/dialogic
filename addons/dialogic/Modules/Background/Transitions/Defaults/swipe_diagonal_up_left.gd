extends "res://addons/dialogic/Modules/Background/Transitions/simple_swipe_transitions.gd"

func _fade() -> void:
	var shader := setup_swipe_shader()
	var texture: GradientTexture2D = shader.get_shader_parameter('wipe_texture')
	texture.fill_from = Vector2.DOWN
	texture.fill_to = Vector2.RIGHT
	tween_shader_progress()
