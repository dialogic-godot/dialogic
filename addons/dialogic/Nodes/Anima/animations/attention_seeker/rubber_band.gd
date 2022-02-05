func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var frames = [
		{ percentage = 0, from = Vector2(1, 1) },
		{ percentage = 30, to = Vector2(1.25, 0.75) },
		{ percentage = 40, to = Vector2(0.75, 1.25) },
		{ percentage = 50, to = Vector2(1.15, 0.85) },
		{ percentage = 65, to = Vector2(0.95, 1.05) },
		{ percentage = 75, to = Vector2(1.05, 0.95) },
		{ percentage = 100, to = Vector2(1, 1) },
	]

	DialogicAnimaPropertiesHelper.set_2D_pivot(data.node, DialogicAnimaPropertiesHelper.PIVOT.CENTER)

	anima_tween.add_frames(data, "scale", frames)
