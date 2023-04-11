@tool
extends Control

## Event block field for a vector.

signal value_changed
var property_name : String

func _ready() -> void:
	$X.value_changed.connect(_on_value_changed)
	$Y.value_changed.connect(_on_value_changed)

func _on_value_changed(property:String, value:float) -> void:
	emit_signal("value_changed", property_name, Vector2($X.value, $Y.value))


func set_value(value:Vector2) -> void:
	$X.set_value(value.x)
	$Y.set_value(value.y)
