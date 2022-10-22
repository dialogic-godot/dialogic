@tool
extends Control

var property_name : String
var placeholder :String= "":
	set(value):
		placeholder = value
		$TextEdit.placeholder_text = placeholder
		
signal value_changed

func _ready():
	$TextEdit.text_changed.connect(text_changed)
	$TextEdit.add_theme_stylebox_override('normal', get_theme_stylebox('normal', 'LineEdit'))
	$TextEdit.add_theme_stylebox_override('focus', get_theme_stylebox('focus', 'LineEdit'))

func text_changed(value = ""):
	emit_signal("value_changed", property_name, $TextEdit.text)

func set_left_text(value):
	$LeftText.text = str(value)
	$LeftText.visible = !value.is_empty()

func set_right_text(value):
	$RightText.text = str(value)
	$RightText.visible = !value.is_empty()

func set_value(value):
	$TextEdit.text = str(value)
