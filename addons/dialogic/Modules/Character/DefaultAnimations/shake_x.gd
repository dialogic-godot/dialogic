extends DialogicAnimation

func animate() -> void:
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	var strength: float = node.get_viewport().size.x/60
	var bound_multitween := DialogicUtil.multitween.bind(node, "position", "animation_shake_x")
	tween.tween_method(bound_multitween, Vector2(), Vector2(1, 0)*strength, time*0.2)
	tween.tween_method(bound_multitween, Vector2(), Vector2(-1,0)*strength, time*0.1)
	tween.tween_method(bound_multitween, Vector2(), Vector2(1, 0)*strength, time*0.1)
	tween.tween_method(bound_multitween, Vector2(), Vector2(-1,0)*strength, time*0.1)
	tween.tween_method(bound_multitween, Vector2(), Vector2(1, 0)*strength, time*0.1)
	tween.tween_method(bound_multitween, Vector2(), Vector2(-1,0)*strength, time*0.1)
	tween.tween_method(bound_multitween, Vector2(), Vector2(0, 0)*strength, time*0.2)
	tween.finished.connect(emit_signal.bind('finished_once'))

func _get_named_variations() -> Dictionary:
	return {
		"shake x": {"type": AnimationType.ACTION},
	}
