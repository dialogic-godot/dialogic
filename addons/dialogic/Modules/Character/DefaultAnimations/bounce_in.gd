extends DialogicAnimation

func animate():
	var tween := (node.create_tween() as Tween)
	node.scale = Vector2()
	node.modulate.a = 0
	
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_parallel()
	tween.tween_property(node, 'scale', Vector2(1,1), time).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, 'modulate:a', 1.0, time)
	tween.finished.connect(emit_signal.bind('finished_once'))
