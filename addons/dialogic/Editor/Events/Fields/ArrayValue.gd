@tool
extends HBoxContainer

## Event block field part for the Array field.

signal value_changed()
W

func set_value(value:String):
	$Value.text = str(value)


func get_value() -> String:
	return $Value.text


func _ready() -> void:
	$Delete.icon = get_theme_icon("Remove", "EditorIcons")


func _on_Delete_pressed() -> void:
	queue_free()
	value_changed.emit()


func _on_Value_text_changed(new_text:String) -> void:
	value_changed.emit()
