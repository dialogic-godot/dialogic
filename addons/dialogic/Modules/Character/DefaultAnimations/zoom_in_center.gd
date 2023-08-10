extends DialogicAnimation

func animate():
	var tween := (node.create_tween() as Tween)
	node.scale = Vector2(0,0)
	node.modulate.a = 0
	node.position = node.get_parent().size/2
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.set_parallel(true)
	
	tween.tween_property(node, 'scale', Vector2(1,1), time)
	tween.tween_property(node, 'position', end_position, time)
	tween.tween_property(node, 'modulate:a', 1, time)
	
	tween.finished.connect(emit_signal.bind('finished_once'))
