func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var opacity_frames = [
		{ from = 1, to = 0 },
	]

	var position_frames = [
		{ percentage = 0, from = 0},
		{ percentage = 100, to = 2000 },
	]

	anima_tween.add_relative_frames(data, "y", position_frames)
	anima_tween.add_frames(data, "opacity", opacity_frames)
