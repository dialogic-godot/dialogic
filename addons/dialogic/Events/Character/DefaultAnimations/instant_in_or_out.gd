extends DialogicAnimation

func animate():
	await node.get_tree().process_frame
	emit_signal('finished')
