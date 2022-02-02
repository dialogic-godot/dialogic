func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var opacity_frames = [
		{ from = 1, to = 0, easing_points = [0.42, 0, 0.58, 1]},
	]

	anima_tween.add_frames(data, "opacity", opacity_frames)
