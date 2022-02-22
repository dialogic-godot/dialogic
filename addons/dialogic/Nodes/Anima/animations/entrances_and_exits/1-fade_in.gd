func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var opacity_frames = [
		{ from = 0, to = 1, easing_points = [0.42, 0, 0.58, 1]},
	]
	anima_tween.add_frames(data, "opacity", opacity_frames)
