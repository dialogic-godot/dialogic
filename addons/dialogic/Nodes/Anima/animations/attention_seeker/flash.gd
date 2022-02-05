func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var frames = [
		{ percentage = 0, from = 1 },
		{ percentage = 25, to = 0 },
		{ percentage = 50, to = 1 },
		{ percentage = 75, to = 0 },
		{ percentage = 100, to = 1 },
	]

	anima_tween.add_frames(data, "opacity", frames)
