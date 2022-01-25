func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var opacity_frames = [
		{ from = 0, to = 1 },
	]

	var size = DialogicAnimaPropertiesHelper.get_size(data.node)

	var position_frames = [
		{ percentage = 0, from = size.y/4 },
		{ percentage = 100, to = -size.y/4 },
	]

	anima_tween.add_relative_frames(data, "y", position_frames)
	anima_tween.add_frames(data, "opacity", opacity_frames)
