tool
extends PanelContainer

export(NodePath) var HideButton_path:NodePath
export(NodePath) var PropertiesContainer_path:NodePath

onready var hide_button_node := get_node(HideButton_path)
onready var properties_container := get_node(PropertiesContainer_path)

func _ready() -> void:
	properties_container.visible = hide_button_node.pressed

func _on_CheckBox_toggled(button_pressed: bool) -> void:
	properties_container.visible = button_pressed
