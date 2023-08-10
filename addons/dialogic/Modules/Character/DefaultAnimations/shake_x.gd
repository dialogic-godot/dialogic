extends DialogicAnimation

func animate():
	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	var strength :float = node.get_viewport().size.x/60
	tween.tween_property(node, 'position:x', orig_pos.x+strength, time*0.2)
	tween.tween_property(node, 'position:x', orig_pos.x-strength, time*0.1)
	tween.tween_property(node, 'position:x', orig_pos.x+strength, time*0.1)
	tween.tween_property(node, 'position:x', orig_pos.x-strength, time*0.1)
	tween.tween_property(node, 'position:x', orig_pos.x+strength, time*0.1)
	tween.tween_property(node, 'position:x', orig_pos.x-strength, time*0.1)
	tween.tween_property(node, 'position:x', orig_pos.x+strength, time*0.1)
	tween.tween_property(node, 'position:x', orig_pos.x, time*0.2)
	
	tween.finished.connect(emit_signal.bind('finished_once'))
