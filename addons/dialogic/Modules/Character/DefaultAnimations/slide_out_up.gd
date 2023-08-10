extends DialogicAnimation

func animate():
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	
	tween.tween_property(node, 'position:y', -node.get_viewport().size.y, time)
	
	tween.finished.connect(emit_signal.bind('finished_once'))
