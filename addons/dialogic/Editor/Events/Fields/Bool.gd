@tool
extends CheckButton

## Event block field for boolean values.

signal value_changed
var property_name : String


func _ready() -> void:
	toggled.connect(_on_value_changed)


func set_value(value:bool) -> void:
	button_pressed = value


func _on_value_changed(value:bool) -> void:
	value_changed.emit(property_name, value)
