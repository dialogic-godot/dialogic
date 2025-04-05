extends DialogicAnimation

func animate() -> void:
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	var end_position_y: float = base_position.y + node.get_parent().global_position.y
	var start_position: float = -get_node_size().y + get_node_origin().y

	if is_reversed:
		tween.set_ease(Tween.EASE_IN)
		end_position_y = -get_node_size().y + get_node_origin().y
		start_position = base_position.y

	node.position.y = start_position

	tween.tween_property(node, 'global_position:y', end_position_y, time)

	await tween.finished
	finished_once.emit()


func _get_named_variations() -> Dictionary:
	return {
		"slide in down": {"reversed": false, "type": AnimationType.IN},
		"slide out up": {"reversed": true, "type": AnimationType.OUT},
	}
