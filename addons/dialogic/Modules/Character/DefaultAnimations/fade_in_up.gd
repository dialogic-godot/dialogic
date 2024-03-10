extends DialogicAnimation

func animate() -> void:
	var tween := (node.create_tween() as Tween)

	var start_pos: Vector2 = orig_pos.y + node.get_viewport().size.y / 5
	var end_pos := orig_pos

	var start_modulation := 0.0
	var end_modulation := 1.0

	if is_reversed:
		end_pos = start_pos
		start_pos = orig_pos
		end_modulation = 0.0
		start_modulation = 1.0

	node.position.y = start_pos

	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_parallel()

	tween.tween_property(node, "position", end_pos, time)

	var property := get_modulation_property()

	var original_modulation: Color = node.get(property)
	original_modulation.a = start_modulation
	node.set(property, original_modulation)
	var modulation_alpha := property + ":a"

	tween.tween_property(node, modulation_alpha, end_modulation, time)

	await tween.finished
	finished_once.emit()

