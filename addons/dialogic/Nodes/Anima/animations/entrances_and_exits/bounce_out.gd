func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var scale_frames = [
		{ percentage = 0, from =  data.node.scale * Vector2(1, 1) },
		{ percentage = 20, to =  data.node.scale * Vector2(0.9, 0.9) },
		{ percentage = 50, to =  data.node.scale * Vector2(1.1, 1.1) },
		{ percentage = 55, to =  data.node.scale * Vector2(1.1, 1.1) },
		{ percentage = 100, to =  data.node.scale * Vector2(0.3, 0.3) },
	]

	var opacity_frames = [
		{ percentage = 0, from = 1 },
		{ percentage = 20, to = 1 },
		{ percentage = 50, to = 1 },
		{ percentage = 55, to = 1 },
		{ percentage = 100, to = 0 },
	]

	DialogicAnimaPropertiesHelper.set_2D_pivot(data.node, DialogicAnimaPropertiesHelper.PIVOT.CENTER)

	anima_tween.add_frames(data, "scale", scale_frames)
	anima_tween.add_frames(data, "opacity", opacity_frames)
