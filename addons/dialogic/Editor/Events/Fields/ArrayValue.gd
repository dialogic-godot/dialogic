@tool
extends HBoxContainer

signal value_changed()

func _ready():
	$Delete.icon = get_theme_icon("Remove", "EditorIcons")
	

func _on_Delete_pressed():
	queue_free()
	emit_signal("value_changed")

func _on_Value_text_changed(new_text):
	emit_signal('value_changed')

func set_value(value):
	$Value.text = str(value)

func get_value():
	return $Value.text
