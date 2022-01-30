func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var opacity_frames = [
		{ from = 0, to = 0 },
	]
	anima_tween.add_frames(data, "opacity", opacity_frames)
