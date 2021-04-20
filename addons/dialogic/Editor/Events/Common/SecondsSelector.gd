tool
extends HBoxContainer

onready var spinbox := $SpinBox

signal value_changed(value)

func set_value(val: float):
	spinbox.value = val


func _on_SpinBox_value_changed(value):
	emit_signal("value_changed", value)
