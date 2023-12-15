extends DialogicBackgroundTransition

func setup_push_shader() -> ShaderMaterial:
	var shader := set_shader(DialogicUtil.get_module_path('Background').path_join("Transitions/push_transition_shader.gdshader"))

	shader.set_shader_parameter("previous_background", prev_texture)
	shader.set_shader_parameter("next_background", next_texture)

	return shader
