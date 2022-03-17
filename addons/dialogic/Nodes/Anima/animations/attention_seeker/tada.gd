func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var rotate_frames = [
		{ percentage = 0, from = 0 },
	]
	var scale_frames = [
		{ percentage = 0, from = DialogicAnimaPropertiesHelper.get_scale(data.node) * Vector2(1, 1) },
	]

	for index in range(2, 9):
		var s = -1 if index % 2 == 0 else 1
		var percent = index * 10.0

		rotate_frames.push_back({ percentage = percent, to = 3 * s })
		scale_frames.push_back({ percentage = percent, to = Vector2(1.1, 1.1) })

	DialogicAnimaPropertiesHelper.set_2D_pivot(data.node, DialogicAnimaPropertiesHelper.PIVOT.CENTER)

	rotate_frames.push_back({percentage = 100, to = 0})
	scale_frames.push_back({percentage = 100, to = Vector2(1, 1)})

	anima_tween.add_frames(data, "rotation", rotate_frames)
	anima_tween.add_frames(data, "scale", scale_frames)
