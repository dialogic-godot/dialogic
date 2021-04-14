tool
extends Tween


func node_appear(node:Control):
	pass


func node_disappear(node:Control):
	pass


func node_fade_in(node:Control):
	interpolate_property(
		node,
		"modulate",
		Color.transparent,
		Color.white,
		1
		)
	pass


func node_fade_out(node:Control):
	pass


func node_dim(node:Control):
	pass


func node_light_up(node:Control):
	pass
