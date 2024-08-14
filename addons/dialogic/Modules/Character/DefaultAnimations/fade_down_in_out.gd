extends DialogicAnimation

func animate() -> void:
	var tween := (node.create_tween() as Tween)

	var start_height: float = base_position.y - node.get_viewport().size.y / 5
	var end_height := base_position.y

	var start_modulation := 0.0
	var end_modulation := 1.0

	if is_reversed:
		end_height = start_height
		start_height = base_position.y
		end_modulation = 0.0
		start_modulation = 1.0

	node.position.y = start_height

	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_parallel()

	var end_postion := Vector2(base_position.x, end_height)
	tween.tween_property(node, "position", end_postion, time)

	var property := get_modulation_property()

	var original_modulation: Color = node.get(property)
	original_modulation.a = start_modulation
	node.set(property, original_modulation)
	var modulation_alpha := property + ":a"

	tween.tween_property(node, modulation_alpha, end_modulation, time)

	await tween.finished
	finished_once.emit()


func _get_named_variations() -> Dictionary:
	return {
		"fade in down": {"reversed": false, "type": AnimationType.IN},
		"fade out up": {"reversed": true, "type": AnimationType.OUT},
	}
