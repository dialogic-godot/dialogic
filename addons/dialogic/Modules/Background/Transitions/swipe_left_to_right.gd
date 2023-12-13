extends "res://addons/dialogic/Modules/Background/simple_swipe_transitions.gd"

func _fade() -> void:
	var shader := setup_swipe_shader()
	shader.set_shader_parameter("wipe_texture", load(this_folder.path_join("swip_left_to_right.tres")))

	tween_shader_progress()
