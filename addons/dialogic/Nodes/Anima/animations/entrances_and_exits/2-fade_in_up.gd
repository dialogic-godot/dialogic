func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var opacity_frames = [
		{ from = 0, to = 1, easing_points = [0.42, 0, 0.58, 1] },
	]

	var size = DialogicAnimaPropertiesHelper.get_size(data.node)

	var position_frames = [
		{ percentage = 0, from = size.y/16, easing_points = [0.42, 0, 0.58, 1] },
		{ percentage = 100, to = -size.y/16, easing_points = [0.42, 0, 0.58, 1] },
	]

	anima_tween.add_relative_frames(data, "y", position_frames)
	anima_tween.add_frames(data, "opacity", opacity_frames)
