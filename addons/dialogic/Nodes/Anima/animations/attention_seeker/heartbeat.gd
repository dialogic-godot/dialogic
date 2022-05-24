func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var scale = DialogicAnimaPropertiesHelper.get_scale(data.node)
	var frames = [
		{ percentage = 0, from = scale * Vector2(1, 1) },
		{ percentage = 14, to = scale * Vector2(1.3, 1.3) },
		{ percentage = 28, to = scale * Vector2(1, 1) },
		{ percentage = 42, to = scale * Vector2(1.3, 1.3) },
		{ percentage = 70, to = scale * Vector2(1, 1) },
		{ percentage = 100, to = scale * Vector2(1, 1) },
	]

	DialogicAnimaPropertiesHelper.set_2D_pivot(data.node, DialogicAnimaPropertiesHelper.PIVOT.CENTER)

	anima_tween.add_frames(data, "scale", frames)
