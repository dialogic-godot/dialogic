extends DialogicAnimation

func animate():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(node, 'scale', Vector2(1,1)*1.1, time*0.3)
	tween.tween_property(node, 'rotation', -0.1, time*0.1).set_delay(time*0.2)
	tween.tween_property(node, 'rotation', 0.1, time*0.1).set_delay(time*0.3)
	tween.tween_property(node, 'rotation', -0.1, time*0.1).set_delay(time*0.4)
	tween.tween_property(node, 'rotation', 0.1, time*0.1).set_delay(time*0.5)
	tween.tween_property(node, 'rotation', -0.1, time*0.1).set_delay(time*0.6)
	tween.chain().tween_property(node, 'scale', Vector2(1,1), time*0.3)
	tween.parallel().tween_property(node, 'rotation', 0.0, time*0.3)
	tween.finished.connect(emit_signal.bind('finished_once'))