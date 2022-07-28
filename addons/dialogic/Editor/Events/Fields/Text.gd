@tool
extends Control

var property_name : String
signal value_changed

func _ready():
	$TextEdit.text_changed.connect(text_changed)

func text_changed(value = ""):
	emit_signal("value_changed", property_name, $TextEdit.text)

func set_left_text(value):
	$LeftText.text = str(value)
	$LeftText.visible = bool(value)

func set_right_text(value):
	$RightText.text = str(value)
	$RightText.visible = bool(value)

func set_value(value):
	$TextEdit.text = str(value)
