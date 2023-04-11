@tool
extends Control

## Event block field that allows entering multiline text (mainly text event).

var property_name : String
signal value_changed

func _ready():
	$TextEdit.text_changed.connect(text_changed)

func text_changed(value = ""):
	emit_signal("value_changed", property_name, $TextEdit.text)

func set_value(value):
	$TextEdit.text = str(value)
	
