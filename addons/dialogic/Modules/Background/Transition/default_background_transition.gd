extends DialogicBackgroundTransition


func _fade() -> void:
	var shader := set_shader(this_folder.path_join("default_background_transition.gdshader"))
	shader.set_shader_parameter("previous_background", prev_texture)
	shader.set_shader_parameter("next_background", next_texture)

	var tween := create_tween()
	tween.tween_property(bg_holder, "material:shader_parameter/progress", 1, time).from(0)

	await tween.finished

	transition_finished.emit()
