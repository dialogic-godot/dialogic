extends DialogicAnimation

func animate() -> void:
	await node.get_tree().process_frame
	finished.emit()


func _get_named_variations() -> Dictionary:
	return {
		"instant in": {"reversed": false, "type": AnimationType.IN},
		"instant out": {"reversed": true, "type": AnimationType.OUT},
	}
