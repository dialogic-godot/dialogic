extends DialogicAnimation

func animate():
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	
	tween.tween_property(node, 'position:y', node.get_viewport().size.y*2, time)
	
	tween.finished.connect(emit_signal.bind('finished_once'))
