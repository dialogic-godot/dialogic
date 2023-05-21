@tool
extends Control

## Event block field for a vector.

signal value_changed
var property_name : String

var current_value := Vector2()

func _ready() -> void:
	$X.value_changed.connect(_on_value_changed)
	$Y.value_changed.connect(_on_value_changed)


func _on_value_changed(property:String, value:float) -> void:
	current_value = Vector2($X.value, $Y.value)
	emit_signal("value_changed", property_name, current_value)


func set_value(value:Vector2) -> void:
	$X.tooltip_text = tooltip_text
	$Y.tooltip_text = tooltip_text
	$X.set_value(value.x)
	$Y.set_value(value.y)
	current_value = value
