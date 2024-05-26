extends DialogicAnimation

func animate() -> void:
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	var target_position := end_position.y
	var start_position: float = -node.get_viewport().size.y

	if is_reversed:
		target_position = -node.get_viewport().size.y
		start_position = end_position.y

	node.position.y = start_position

	tween.tween_property(node, 'position:y', target_position, time)

	await tween.finished
	finished_once.emit()
