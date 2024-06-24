extends DialogicAnimation


func animate() -> void:
	var tween := (node.create_tween() as Tween)

	var end_scale: Vector2 = node.scale
	var end_modulate_alpha := 1.0
	var modulation_property := get_modulation_property()

	if is_reversed:
		end_scale = Vector2(0, 0)
		end_modulate_alpha = 0.0

	else:
		node.scale = Vector2(0, 0)
		var original_modulation: Color = node.get(modulation_property)
		original_modulation.a = 0.0
		node.set(modulation_property, original_modulation)


	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_parallel()

	(tween.tween_property(node, "scale", end_scale, time)
		.set_trans(Tween.TRANS_SPRING)
		.set_ease(Tween.EASE_OUT))
	tween.tween_property(node, modulation_property + ":a", end_modulate_alpha, time)

	await tween.finished
	finished_once.emit()


func _get_named_variations() -> Dictionary:
	return {
		"bounce in": {"reversed": false, "type": AnimationType.IN},
		"bounce out": {"reversed": true, "type": AnimationType.OUT},
	}
