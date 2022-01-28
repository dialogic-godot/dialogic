func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var node = data.node
	var start_position = DialogicAnimaPropertiesHelper.get_position(node)
	var size = DialogicAnimaPropertiesHelper.get_size(node)

	var x_frames = [
		{ percentage = 0, from = start_position.x },
		{ percentage = 15, to = start_position.x + size.x * -0.25 },
		{ percentage = 30, to = start_position.x + size.x * 0.2 },
		{ percentage = 45, to = start_position.x + size.x * -0.15 },
		{ percentage = 60, to = start_position.x + size.x * 0.1 },
		{ percentage = 75, to = start_position.x + size.x * -0.05 },
		{ percentage = 100, to = start_position.x },
	]

	var rotation_frames = [
		{ percentage = 0, from = 0 },
		{ percentage = 15, to = -5 },
		{ percentage = 30, to = 3 },
		{ percentage = 45, to = -3 },
		{ percentage = 60, to = 2 },
		{ percentage = 75, to = -1 },
		{ percentage = 100, to = 0 },
	]

	DialogicAnimaPropertiesHelper.set_2D_pivot(data.node, DialogicAnimaPropertiesHelper.PIVOT.TOP_CENTER)
	anima_tween.add_frames(data, "x", x_frames)
	anima_tween.add_frames(data, "rotation", rotation_frames)
