@tool
extends PanelContainer

## Event block field part for the Array field.

signal value_changed()

var value_field: Node
var value_type: int = -1

var current_value: Variant

func _ready() -> void:
	%FlexValue.value_changed.connect(emit_signal.bind("value_changed"))
	%Delete.icon = get_theme_icon("Remove", "EditorIcons")


func set_value(value:Variant):
	%FlexValue.set_value(value)


func get_value() -> Variant:
	return %FlexValue.current_value


func _on_delete_pressed() -> void:
	queue_free()
	value_changed.emit()
