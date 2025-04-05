extends DialogicAnimation


func animate() -> void:
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	var end_position_x: float = base_position.x + node.get_parent().global_position.x

	if is_reversed:
		end_position_x = - get_node_size().x + get_node_origin().x
		tween.set_ease(Tween.EASE_IN)

	else:
		node.global_position.x = -get_node_size().x + get_node_origin().x

	tween.tween_property(node, 'global_position:x', end_position_x, time)

	await tween.finished
	finished_once.emit()


func _get_named_variations() -> Dictionary:
	return {
		"slide from left": {"reversed": false, "type": AnimationType.IN},
		"slide to left": {"reversed": true, "type": AnimationType.OUT},
	}
