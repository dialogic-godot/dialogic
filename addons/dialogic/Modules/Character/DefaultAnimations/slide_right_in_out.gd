extends DialogicAnimation

func animate() -> void:
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	var viewport_x: float = node.get_viewport().size.x

	var start_position_x: float = viewport_x + viewport_x / 5
	var end_position_x := base_position.x

	if is_reversed:
		start_position_x = base_position.x
		end_position_x = viewport_x + node.get_viewport().size.x / 5


	node.position.x = start_position_x
	tween.tween_property(node, 'position:x', end_position_x, time)

	tween.finished.connect(emit_signal.bind('finished_once'))


func _get_named_variations() -> Dictionary:
	return {
		"slide in right": {"reversed": false, "type": AnimationType.IN},
		"slide out left": {"reversed": true, "type": AnimationType.OUT},
	}
