extends DialogicAnimation


func animate() -> void:
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	var end_position_x: float = base_position.x

	if is_reversed:
		end_position_x = -node.get_viewport().size.x / 2

	else:
		node.position.x = -node.get_viewport().size.x / 5

	tween.tween_property(node, 'position:x', end_position_x, time)

	await tween.finished
	finished_once.emit()


func _get_named_variations() -> Dictionary:
	return {
		"slide in left": {"reversed": false, "type": AnimationType.IN},
		"slide out right": {"reversed": true, "type": AnimationType.OUT},
	}
