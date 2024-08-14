extends DialogicAnimation

func animate() -> void:
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, 'position:y', base_position.y-node.get_viewport().size.y/10, time*0.4).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property(node, 'scale:y', base_scale.y*1.05, time*0.4).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(node, 'position:y', base_position.y, time*0.6).set_trans(Tween.TRANS_BOUNCE)
	tween.parallel().tween_property(node, 'scale:y', base_scale.y, time*0.6).set_trans(Tween.TRANS_BOUNCE)
	tween.finished.connect(emit_signal.bind('finished_once'))


func _get_named_variations() -> Dictionary:
	return {
		"bounce": {"type": AnimationType.ACTION},
	}
