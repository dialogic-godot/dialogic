extends DialogicAnimation

func animate() -> void:
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	var start_position_y: float = get_viewport_size().y + get_node_origin().y
	var end_position_y: float = base_position.y + node.get_parent().global_position.y

	if is_reversed:
		tween.set_ease(Tween.EASE_IN)
		start_position_y = end_position_y
		end_position_y = get_viewport_size().y + get_node_origin().y

	node.global_position.y = start_position_y
	tween.tween_property(node, 'global_position:y', end_position_y, time)

	await tween.finished
	finished_once.emit()


func _get_named_variations() -> Dictionary:
	return {
		"slide in up": {"reversed": false, "type": AnimationType.IN},
		"slide out down": {"reversed": true, "type": AnimationType.OUT},
	}
