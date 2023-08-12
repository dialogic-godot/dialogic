extends DialogicAnimation

func animate():
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	tween.set_parallel(true)
	
	tween.tween_property(node, 'scale', Vector2(0,0), time)
	tween.tween_property(node, 'position', node.get_parent().size/2, time)
	tween.tween_property(node, 'modulate:a', 0, time)
	
	tween.finished.connect(emit_signal.bind('finished_once'))
