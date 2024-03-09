extends DialogicAnimation

func animate() -> void:
	var tween := (node.create_tween() as Tween)

	node.modulate.a = 0
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_parallel()

	tween.tween_property(node, 'modulate:a', 1.0, time)

	await tween.finished
	finished_once.emit()

