extends DialogicAnimation

func animate() -> void:
	await node.get_tree().process_frame
	finished.emit()
