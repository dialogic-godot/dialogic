func generate_animation(anima_tween: Tween, data: Dictionary) -> void:
	var start = DialogicAnimaPropertiesHelper.get_position(data.node)

	var shake_frames = [
		{ percentage = 0, from = 0 },
		{ percentage = 6.5, to = -6 },
		{ percentage = 18.5, to = +5 },
		{ percentage = 31.5, to = -3 },
		{ percentage = 43.5, to = +2 },
		{ percentage = 50, to = 0 },
		{ percentage = 100, to = 0 },
	]

	var rotate_frames = [
		{ percentage = 0, to = 0 },
		{ percentage = 6.5, to = -9 },
		{ percentage = 18.5, to = +7 },
		{ percentage = 31.5, to = -5 },
		{ percentage = 43.5, to = +3 },
		{ percentage = 50, to = 0 },
		{ percentage = 100, to = 0 },
	]

	DialogicAnimaPropertiesHelper.set_2D_pivot(data.node, DialogicAnimaPropertiesHelper.PIVOT.CENTER)

	anima_tween.add_relative_frames(data, "x", shake_frames)
	anima_tween.add_frames(data, "rotation", rotate_frames)
