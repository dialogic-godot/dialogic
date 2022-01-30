func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var opacity_frames = [
		{ from = 1, to = 0 },
	]

	var size = DialogicAnimaPropertiesHelper.get_size(data.node)

	var position_frames = [
		{ from = 0, to = size.y/4 },
	]

	anima_tween.add_relative_frames(data, "y", position_frames)
	anima_tween.add_frames(data, "opacity", opacity_frames)
