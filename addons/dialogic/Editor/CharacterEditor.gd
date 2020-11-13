tool
extends ScrollContainer


func _ready():
	pass # Replace with function body.

func _on_CheckBox_toggled(button_pressed):
	$HBoxContainer/Container/DisplayName.visible = button_pressed
