tool
extends PanelContainer

export(NodePath) var HideButton_path:NodePath
export(NodePath) var DescriptionContainer_path:NodePath

onready var hide_button_node := get_node(HideButton_path)
onready var description_container := get_node(DescriptionContainer_path)

func _ready() -> void:
	description_container.visible = hide_button_node.pressed

func _on_CheckBox_toggled(button_pressed: bool) -> void:
	description_container.visible = button_pressed
