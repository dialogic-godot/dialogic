@tool
extends CheckButton

## Event block field for boolean values.

signal value_changed
var property_name : String


func _ready() -> void:
	toggled.connect(_on_value_changed)


func set_value(value:Variant) -> void:
	match DialogicUtil.get_variable_value_type(value):
		DialogicUtil.VarTypes.STRING:
			button_pressed = value and not value == "false"
		_:
			button_pressed = value and true


func _on_value_changed(value:bool) -> void:
	value_changed.emit(property_name, value)
