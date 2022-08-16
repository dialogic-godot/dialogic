extends DialogicAnimation

func animate():
	var tween = (node.create_tween() as Tween)
	node.scale = Vector2(1,1)
	node.modulate.a = 1
	
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_parallel()
	
	tween.tween_property(node, 'scale', Vector2(), time).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN)
	tween.tween_property(node, 'modulate:a', 0.0, time)
	
	tween.finished.connect(emit_signal.bind('finished_once'))
