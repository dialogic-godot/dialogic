extends DialogicAnimation

func animate() -> void:
	var modulate_property := get_modulation_property()
	var modulate_alpha_property := modulate_property + ":a"

	var end_scale: Vector2 = node.scale
	var end_modulation_alpha := 1.0

	if is_reversed:
		end_scale = Vector2(0, 0)
		end_modulation_alpha = 0.0

	else:
		node.scale = Vector2(0,0)

		var original_modulation: Color = node.get(modulate_property)
		original_modulation.a = 0.0
		node.set(modulate_property, original_modulation)

	var tween := (node.create_tween() as Tween)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.set_parallel(true)
	tween.tween_property(node, "scale", end_scale, time)
	tween.tween_property(node, modulate_alpha_property, end_modulation_alpha, time)

	await tween.finished
	finished_once.emit()


func _get_named_variations() -> Dictionary:
	return {
		"zoom in": {"reversed": false, "type": AnimationType.IN},
		"zoom out": {"reversed": true, "type": AnimationType.OUT},
	}
