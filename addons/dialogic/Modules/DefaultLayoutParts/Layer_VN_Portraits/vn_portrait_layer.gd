@tool
extends DialogicLayoutLayer

## A layer that allows showing 5 portraits, like in a visual novel.

## The canvas layer that the portraits are on.
@export var portrait_size_mode: DialogicNode_PortraitContainer.SizeModes = DialogicNode_PortraitContainer.SizeModes.FIT_SCALE_HEIGHT


func _apply_export_overrides() -> void:
	# apply portrait size
	for child: DialogicNode_PortraitContainer in %Portraits.get_children():
		child.size_mode = portrait_size_mode
		child.update_portrait_transforms()

