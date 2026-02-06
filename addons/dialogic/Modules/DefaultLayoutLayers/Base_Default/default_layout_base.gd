@tool
extends DialogicLayoutBase

## The default layout base scene.

@export var canvas_layer: int = 1
@export var theme: Theme :
	set(t):
		theme = t
		for i in get_children():
			if i is Control:
				i.theme = theme
