extends DialogicAnimation

func animate():
	var tween := (node.create_tween() as Tween)
	node.scale = Vector2(0,0)
	node.modulate.a = 0
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.set_parallel(true)
	
#	node.position.y = node.get_viewport().size.y/2
	tween.tween_property(node, 'scale', Vector2(1,1), time)
#	tween.tween_property(node, 'position:y', end_position.y, time)
	tween.tween_property(node, 'modulate:a', 1, time)
	
	tween.finished.connect(emit_signal.bind('finished_once'))
