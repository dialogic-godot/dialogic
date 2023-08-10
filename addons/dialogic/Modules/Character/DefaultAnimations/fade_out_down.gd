extends DialogicAnimation

func animate():
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_parallel()
	
	tween.tween_property(node, 'position:y', orig_pos.y + node.get_viewport().size.y/5, time)
	tween.tween_property(node, 'modulate:a', 0.0, time)
	
	tween.finished.connect(emit_signal.bind('finished_once'))
