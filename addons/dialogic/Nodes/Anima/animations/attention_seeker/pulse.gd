func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var frames = [
		{ percentage = 0, from = Vector2(1, 1) },
		{ percentage = 50, to = Vector2(1.05, 1.05), easing = anima_tween.EASING.EASE_IN_OUT_SINE },
		{ percentage = 100, to = Vector2(1, 1) },
	]

	DialogicAnimaPropertiesHelper.set_2D_pivot(data.node, DialogicAnimaPropertiesHelper.PIVOT.CENTER)

	anima_tween.add_frames(data, "scale", frames)
