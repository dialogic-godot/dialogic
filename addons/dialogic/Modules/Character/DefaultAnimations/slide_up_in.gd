extends DialogicAnimation

func animate() -> void:
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	var start_position_y: float = node.get_viewport().size.y * 2
	var end_position_y := end_position.y

	if is_reversed:
		start_position_y = end_position.y
		end_position_y = node.get_viewport().size.y * 2

	node.position.y = start_position_y
	tween.tween_property(node, 'position:y', end_position_y, time)

	await tween.finished
	finished_once.emit()


func _get_named_variations() -> Dictionary:
	return {
		"slide in up": {"reversed": false, "type": AnimationType.IN},
		"slide out down": {"reversed": true, "type": AnimationType.OUT},
	}
