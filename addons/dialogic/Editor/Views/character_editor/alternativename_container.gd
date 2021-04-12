tool
extends PanelContainer

export(NodePath) var AltNameBool_path:NodePath
export(NodePath) var AltNameContainer_path:NodePath

onready var alt_name_btn_node = get_node(AltNameBool_path)
onready var alt_name_container_node = get_node(AltNameContainer_path)

func _ready() -> void:
	pass


func _on_CheckButton_toggled(button_pressed: bool) -> void:
	alt_name_container_node.visible = button_pressed
