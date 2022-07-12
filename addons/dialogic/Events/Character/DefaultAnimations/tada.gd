extends DialogicAnimation

func animate():
	var tween = (node.get_tree().create_tween() as SceneTreeTween)
	tween.bind_node(self)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(node, 'scale', Vector2(1,1)*1.1, time*0.3)
	tween.tween_property(node, 'rotation_degrees', -5.0, time*0.1).set_delay(time*0.2)
	tween.tween_property(node, 'rotation_degrees', 5.0, time*0.1).set_delay(time*0.3)
	tween.tween_property(node, 'rotation_degrees', -5.0, time*0.1).set_delay(time*0.4)
	tween.tween_property(node, 'rotation_degrees', 5.0, time*0.1).set_delay(time*0.5)
	tween.tween_property(node, 'rotation_degrees', -5.0, time*0.1).set_delay(time*0.6)
	tween.chain().tween_property(node, 'scale', Vector2(1,1), time*0.3)
	tween.parallel().tween_property(node, 'rotation_degrees', 0.0, time*0.3)
	
	tween.connect("finished", self, 'emit_signal', ['finished_once'])
