@tool
extends LineEdit

## Event block field for a single line of text.

signal value_changed
var property_name : String

var placeholder :String= "":
	set(value):
		placeholder = value
		placeholder_text = placeholder
		

func _ready() -> void:
	text_changed.connect(_on_text_changed)
	add_theme_stylebox_override('normal', get_theme_stylebox('normal', 'LineEdit'))
	add_theme_stylebox_override('focus', get_theme_stylebox('focus', 'LineEdit'))


func _on_text_changed(value := "") -> void:
	value_changed.emit(property_name, text)


func set_value(value:String) -> void:
	text = str(value)
