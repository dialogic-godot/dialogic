extends DialogicBackgroundTransition

func setup_swipe_shader() -> ShaderMaterial:
	var shader := set_shader()
	shader.set_shader_parameter("wipe_texture", load(
		DialogicUtil.get_module_path('Background').path_join("Transitions/simple_swipe_gradient.tres")
	))

	shader.set_shader_parameter("feather", 0.3)

	shader.set_shader_parameter("previous_background", prev_texture)
	shader.set_shader_parameter("next_background", next_texture)

	return shader
