func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var frames = [
		{ percentage = 0, to = 0 },
		{ percentage = 10, to = -10 },
		{ percentage = 20, to = +20 },
		{ percentage = 30, to = -20 },
		{ percentage = 40, to = +20 },
		{ percentage = 50, to = -20 },
		{ percentage = 60, to = +20 },
		{ percentage = 70, to = -20 },
		{ percentage = 80, to = +20 },
		{ percentage = 90, to = -20 },
		{ percentage = 100, to = +10 },
	]

	anima_tween.add_relative_frames(data, "x", frames)
