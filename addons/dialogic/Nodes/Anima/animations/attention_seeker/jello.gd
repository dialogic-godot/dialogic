func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var start_x = data.node.get_global_transform().y.x
	var start_y = data.node.get_global_transform().x.y

	var skew_x := []
	var skew_y := []

	var values = [
		{ percentage = 0, add = 0 },
		{ percentage = 11.1, add = 0 },
		{ percentage = 22.2, add = - 0.3 },
		{ percentage = 33.3, add = + 0.265 },
		{ percentage = 44.4, add = - 0.1325 },
		{ percentage = 55.5, add = + 0.06625 },
		{ percentage = 66.6, add = - 0.033125 },
		{ percentage = 77.7, add = + 0.0165625 },
		{ percentage = 88.8, add = - 0.00828125},
		{ percentage = 100, add = 0 },
	]

	for value in values:
		skew_x.push_back({ percentage = value.percentage, to = start_x + value.add })
		skew_y.push_back({ percentage = value.percentage, to = start_y + value.add })

	DialogicAnimaPropertiesHelper.set_2D_pivot(data.node, DialogicAnimaPropertiesHelper.PIVOT.CENTER)

	# Skew works only with Node2D
	if not data.node is Node2D:
		return

	anima_tween.add_frames(data, "skew:x", skew_x)
	anima_tween.add_frames(data, "skew:y", skew_y)
