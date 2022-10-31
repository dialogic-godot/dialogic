@tool
extends Control

var property_name : String
signal value_changed

func _ready():
	$X.value_changed.connect(_on_value_changed)
	$Y.value_changed.connect(_on_value_changed)

func _on_value_changed(property, value):
	emit_signal("value_changed", property_name, Vector2($X.value, $Y.value))

func set_right_text(value):
	$RightText.text = str(value)
	$RightText.visible = !value.is_empty()

func set_left_text(value):
	$LeftText.text = str(value)
	$LeftText.visible = !value.is_empty()

func set_value(value:Vector2):
	$X.set_value(value.x)
	$Y.set_value(value.y)
