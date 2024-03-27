extends DialogicAnimation

func animate() -> void:

	var modulation_property := get_modulation_property()
	var end_modulation_alpha := 1.0

	if is_reversed:
		end_modulation_alpha = 0.0

	else:
		var original_modulation: Color = node.get(modulation_property)
		original_modulation.a = 0.0
		node.set(modulation_property, original_modulation)

	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, modulation_property + ":a", end_modulation_alpha, time)

	await tween.finished
	finished_once.emit()

