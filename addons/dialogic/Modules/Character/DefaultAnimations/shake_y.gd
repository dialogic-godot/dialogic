extends DialogicAnimation

func animate() -> void:
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	var strength: float = node.get_viewport().size.y/40
	tween.tween_property(node, 'position:y', base_position.y + strength, time * 0.2)
	tween.tween_property(node, 'position:y', base_position.y - strength, time * 0.1)
	tween.tween_property(node, 'position:y', base_position.y + strength, time * 0.1)
	tween.tween_property(node, 'position:y', base_position.y - strength, time * 0.1)
	tween.tween_property(node, 'position:y', base_position.y + strength, time * 0.1)
	tween.tween_property(node, 'position:y', base_position.y - strength, time * 0.1)
	tween.tween_property(node, 'position:y', base_position.y + strength, time * 0.1)
	tween.tween_property(node, 'position:y', base_position.y, time * 0.2)

	tween.finished.connect(emit_signal.bind('finished_once'))


func _get_named_variations() -> Dictionary:
	return {
		"shake y": {"type": AnimationType.ACTION},
	}
