extends DialogicAnimation

func animate():
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	node.position.x = -node.get_viewport().size.x/5
	tween.tween_property(node, 'position:x', end_position.x, time)
	
	tween.finished.connect(emit_signal.bind('finished_once'))
