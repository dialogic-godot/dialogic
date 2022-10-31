@tool
extends HBoxContainer

var property_name : String
signal value_changed

func _ready():
	$Toggle.toggled.connect(_on_value_changed)


func set_value(value:bool):
	$Toggle.button_pressed = value


func _on_value_changed(value):
	emit_signal("value_changed", property_name, value)


func set_right_text(value):
	$RightText.text = str(value)

func set_left_text(value):
	$LeftText.text = str(value)
