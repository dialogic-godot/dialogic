extends DialogicAnimation

func animate() -> void:
	var tween := (node.create_tween() as Tween)
	tween.tween_property(node, 'scale', Vector2(1,1)*1.2, time*0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, 'scale', Vector2(1,1), time*0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(emit_signal.bind('finished_once'))


func _get_named_variations() -> Dictionary:
	return {
		"heartbeat": {"type": AnimationType.ACTION},
	}
