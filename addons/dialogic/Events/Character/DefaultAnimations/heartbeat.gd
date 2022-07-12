extends DialogicAnimation

func animate():
	var tween = (node.get_tree().create_tween() as SceneTreeTween)
	tween.bind_node(self)
	#tween.set_parallel(true)
	#node.scale = Vector2(1,1)*1.2
	tween.tween_property(node, 'scale', Vector2(1,1)*1.2, time*0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	#tween.tween_property(node, 'scale', Vector2(1,1)*1.1, time*0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, 'scale', Vector2(1,1), time*0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	tween.connect("finished", self, 'emit_signal', ['finished_once'])
