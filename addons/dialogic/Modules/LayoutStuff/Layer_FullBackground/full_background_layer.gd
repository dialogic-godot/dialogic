@tool
extends DialogicLayoutLayer

## A layer that holds full-screen backgrounds.

@export_group('Transition')
@export_file('*.tres') var transition_shader_material := ""


func _apply_export_overrides() -> void:
	if ResourceLoader.exists(transition_shader_material):
		$DialogicNode_BackgroundHolder.material = load(transition_shader_material)
