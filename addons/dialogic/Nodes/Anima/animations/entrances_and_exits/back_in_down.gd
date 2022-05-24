func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var y_frames = [
		{ percentage = 0, to = -1200 },
		{ percentage = 80, to = +1200 },
		{ percentage = 100, to = 0 },
	]
	
	var scale = DialogicAnimaPropertiesHelper.get_scale(data.node)
	var scale_frames = [
		{ percentage = 0, from = scale * Vector2(0.7, 0.7) },
		{ percentage = 80, to = scale * Vector2(0.7, 0.7) },
		{ percentage = 100, to = scale * Vector2(1, 1) },
	]

	var opacity_frames = [
		{ percentage = 0, from = 0.7 },
		{ percentage = 80, to = 0.7 },
		{ percentage = 100, to = 1 },
	]

	DialogicAnimaPropertiesHelper.set_2D_pivot(data.node, DialogicAnimaPropertiesHelper.PIVOT.CENTER)

	anima_tween.add_relative_frames(data, "y", y_frames)
	anima_tween.add_frames(data, "scale", scale_frames)
	anima_tween.add_frames(data, "opacity", opacity_frames)
