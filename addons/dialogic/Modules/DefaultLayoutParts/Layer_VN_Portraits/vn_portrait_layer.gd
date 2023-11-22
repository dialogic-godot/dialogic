@tool
extends DialogicLayoutLayer

## A layer that allows showing 5 portraits, like in a visual novel.

## The canvas layer that the portraits are on.
@export var canvas_layer := 0
@export var portrait_size_mode := DialogicNode_PortraitContainer.SizeModes.FIT_SCALE_HEIGHT


func _apply_export_overrides():
	# apply layer
	self.layer = canvas_layer

	# apply portrait size
	for child in %Portraits.get_children():
		child.size_mode = portrait_size_mode

