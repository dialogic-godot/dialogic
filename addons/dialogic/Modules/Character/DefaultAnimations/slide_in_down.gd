extends DialogicAnimation

func animate():
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	node.position.y = -node.get_viewport().size.y
	tween.tween_property(node, 'position:y', end_position.y, time)
	
	tween.finished.connect(emit_signal.bind('finished_once'))
