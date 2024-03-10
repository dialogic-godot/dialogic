extends DialogicAnimation

func animate() -> void:
	var tween := (node.create_tween() as Tween)

	var start := 0.0
	var end := 1.0

	if is_reversed:
		start = 1.0
		end = 0.0

	var property := get_modulation_property()
	var original_color: Color = node.get(property)
	original_color.a = start
	node.set(property, original_color)

	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, property + ":a", end, time)

	await tween.finished
	finished_once.emit()

