func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var scale = DialogicAnimaPropertiesHelper.get_scale(data.node)
	var scale_frames = [
		{ percentage = 0, from = scale * Vector2(0.3, 0.3), easing_points = [0.215, 0.61, 0.355, 1] },
		{ percentage = 20, to = scale * Vector2(1, 1), easing_points = [0.215, 0.61, 0.355, 1] },
		{ percentage = 40, to = scale * Vector2(0.9, 0.9), easing_points = [0.215, 0.61, 0.355, 1] },
		{ percentage = 60, to = scale * Vector2(1.03, 1.03), easing_points = [0.215, 0.61, 0.355, 1] },
		{ percentage = 80, to = scale * Vector2(0.97, 0.97), easing_points = [0.215, 0.61, 0.355, 1] },
		{ percentage = 100, to = scale * Vector2(1, 1) },
	]

	var opacity_frames = [
		{ percentage = 0, from = 0 },
		{ percentage = 60, to = 1 },
		{ percentage = 100, to = 1 },
	]

	DialogicAnimaPropertiesHelper.set_2D_pivot(data.node, DialogicAnimaPropertiesHelper.PIVOT.CENTER)

	anima_tween.add_frames(data, "scale", scale_frames)
	anima_tween.add_frames(data, "opacity", opacity_frames)
