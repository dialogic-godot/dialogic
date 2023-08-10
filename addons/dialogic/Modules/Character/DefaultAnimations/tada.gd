extends DialogicAnimation

func animate():
	var tween := (node.create_tween() as Tween)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var strength :float = 0.01
	
	tween.set_parallel(true)
	tween.tween_property(node, 'scale', Vector2(1,1)*(1+strength), time*0.3)
	tween.tween_property(node, 'rotation', -strength, time*0.1).set_delay(time*0.2)
	tween.tween_property(node, 'rotation', strength, time*0.1).set_delay(time*0.3)
	tween.tween_property(node, 'rotation', -strength, time*0.1).set_delay(time*0.4)
	tween.tween_property(node, 'rotation', strength, time*0.1).set_delay(time*0.5)
	tween.tween_property(node, 'rotation', -strength, time*0.1).set_delay(time*0.6)
	tween.chain().tween_property(node, 'scale', Vector2(1,1), time*0.3)
	tween.parallel().tween_property(node, 'rotation', 0.0, time*0.3)
	
	tween.finished.connect(emit_signal.bind('finished_once'))
