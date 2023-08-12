extends DialogicAnimation

func animate():
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	var strength :float = node.get_viewport().size.y/40
	tween.tween_property(node, 'position:y', orig_pos.y+strength, time*0.2)
	tween.tween_property(node, 'position:y', orig_pos.y-strength, time*0.1)
	tween.tween_property(node, 'position:y', orig_pos.y+strength, time*0.1)
	tween.tween_property(node, 'position:y', orig_pos.y-strength, time*0.1)
	tween.tween_property(node, 'position:y', orig_pos.y+strength, time*0.1)
	tween.tween_property(node, 'position:y', orig_pos.y-strength, time*0.1)
	tween.tween_property(node, 'position:y', orig_pos.y+strength, time*0.1)
	tween.tween_property(node, 'position:y', orig_pos.y, time*0.2)
	
	tween.finished.connect(emit_signal.bind('finished_once'))
