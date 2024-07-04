@tool
extends PanelContainer

## Event block field part for the Dictionary field.

signal value_changed()


func set_key(value:String) -> void:
	%Key.text = str(value)


func get_key() -> String:
	return %Key.text


func set_value(value:Variant) -> void:
	%FlexValue.set_value(value)


func get_value() -> Variant:
	return %FlexValue.current_value


func _ready() -> void:
	%Delete.icon = get_theme_icon("Remove", "EditorIcons")


func focus_key() -> void:
	%Key.grab_focus()


func _on_key_text_changed(new_text: String) -> void:
	value_changed.emit()


func _on_flex_value_value_changed() -> void:
	value_changed.emit()


func _on_delete_pressed() -> void:
	queue_free()
	value_changed.emit()

