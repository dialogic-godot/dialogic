@icon("node_name_label_icon.svg")
extends Label
class_name DialogicNode_NameLabel

## A dialogic node that shows the name of the current speaker.

## If true, the [param name_label_root] node will be hidden if no character speaks.
@export var hide_when_empty := true
## The node that should be hidden and shown based on [param hide_when_empty]. If not set, defaults to this node itself.
@export var name_label_root: Node = self
## If true [param self_modulate] is set to the current speakers color (set in the character editor).
@export var use_character_color := true


func _ready() -> void:
	add_to_group('dialogic_name_label')
	if hide_when_empty:
		name_label_root.visible = false
	text = ""


func _set(property, what):
	if property == 'text' and typeof(what) == TYPE_STRING:
		text = what
		if hide_when_empty:
			name_label_root.visible = !what.is_empty()
		else:
			name_label_root.show()
		return true
