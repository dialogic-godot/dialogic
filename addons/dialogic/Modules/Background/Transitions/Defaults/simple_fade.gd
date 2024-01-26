extends DialogicBackgroundTransition


func _fade() -> void:
	var shader := set_shader()
	shader.set_shader_parameter("wipe_texture", load(this_folder.path_join("simple_fade.tres")))

	shader.set_shader_parameter("feather", 1)

	shader.set_shader_parameter("previous_background", prev_texture)
	shader.set_shader_parameter("next_background", next_texture)

	tween_shader_progress()
