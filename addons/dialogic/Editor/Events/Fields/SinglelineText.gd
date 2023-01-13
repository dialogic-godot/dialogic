@tool
extends Control

## Event block field for a single line of text.

signal value_changed
var property_name : String

var placeholder :String= "":
	set(value):
		placeholder = value
		$TextEdit.placeholder_text = placeholder
		

func _ready() -> void:
	$TextEdit.text_changed.connect(text_changed)
	$TextEdit.add_theme_stylebox_override('normal', get_theme_stylebox('normal', 'LineEdit'))
	$TextEdit.add_theme_stylebox_override('focus', get_theme_stylebox('focus', 'LineEdit'))

func text_changed(value := "") -> void:
	emit_signal("value_changed", property_name, $TextEdit.text)

func set_value(value:String) -> void:
	$TextEdit.text = str(value)
