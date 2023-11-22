@tool
extends DialogicLayoutBase

## The default layout base scene.

@export var canvas_layer := 1

@export_subgroup("Global")
@export var global_bg_color := Color(0, 0, 0, 0.9)
@export var global_font_color := Color("white")
@export_file('*.ttf') var global_font := ""
@export var global_font_size := 18


func _apply_export_overrides() -> void:
	# apply layer
	self.layer = canvas_layer


