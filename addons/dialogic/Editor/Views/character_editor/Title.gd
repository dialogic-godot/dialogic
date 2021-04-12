tool
extends PanelContainer

export(NodePath) var Properties_path:NodePath

onready var properties_node := get_node(Properties_path)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			properties_node.visible = !properties_node.visible
			if get_tree():
				get_tree().set_input_as_handled()
