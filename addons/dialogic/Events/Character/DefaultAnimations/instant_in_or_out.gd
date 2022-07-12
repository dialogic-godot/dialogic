extends DialogicAnimation

func animate():
	yield(node.get_tree(), "idle_frame")
	emit_signal('finished')
