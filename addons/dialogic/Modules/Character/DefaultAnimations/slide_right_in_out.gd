extends DialogicAnimation

func animate() -> void:
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	var viewport_x: float = get_viewport_size().x
	var end_position_x : float = base_position.x + node.get_parent().global_position.x

	if is_reversed:
		end_position_x = viewport_x + get_node_origin().x
		tween.set_ease(Tween.EASE_IN)
	else:
		node.global_position.x = viewport_x + get_node_origin().x

	tween.tween_property(node, 'global_position:x', end_position_x, time)
	tween.finished.connect(emit_signal.bind('finished_once'))


func _get_named_variations() -> Dictionary:
	return {
		"slide from right": {"reversed": false, "type": AnimationType.IN},
		"slide to right": {"reversed": true, "type": AnimationType.OUT},
	}
