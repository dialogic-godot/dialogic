@tool
extends Control

var property_name : String
signal value_changed

func _ready():
	$TextEdit.text_changed.connect(text_changed)
	DCSS.style($TextEdit, {
		'border-radius': 3,
		'border-color': Color('#14161A'),
		'border': 1,
		'background': Color('#1D1F25'),
		'padding': [5, 5],
	})

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
