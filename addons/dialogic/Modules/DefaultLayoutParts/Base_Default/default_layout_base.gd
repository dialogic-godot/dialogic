@tool
extends DialogicLayoutBase

## The default layout base scene.

@export var canvas_layer: int = 1

@export_subgroup("Global")
@export var global_bg_color: Color = Color(0, 0, 0, 0.9)
@export var global_font_color: Color = Color("white")
@export_file('*.ttf') var global_font: String = ""
@export var global_font_size: int = 18


func _apply_export_overrides() -> void:
	# apply layer
	set(&'layer', canvas_layer)


