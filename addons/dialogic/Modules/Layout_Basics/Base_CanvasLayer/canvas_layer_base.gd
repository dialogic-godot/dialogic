@tool
extends DialogicLayoutBase

## The default layout base scene.

## Theme that will be applied to all the control-based children.
@export var theme: Theme :
	set(t):
		theme = t
		for i in get_children():
			if i is Control:
				i.theme = theme
