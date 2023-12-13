extends DialogicBackgroundTransition

func setup_swipe_shader() -> ShaderMaterial:
	var shader := set_shader(this_folder.path_join("simple_fade_shader.gdshader"))

	shader.set_shader_parameter("feather", 0.2)

	shader.set_shader_parameter("previous_background", prev_texture)
	shader.set_shader_parameter("next_background", next_texture)

	return shader
