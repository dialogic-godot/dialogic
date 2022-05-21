tool
extends Control

var property_name : String
signal value_changed

func _ready():
	$TextEdit.connect("text_changed", self,  'text_changed')

func text_changed(value = ""):
	emit_signal("value_changed", property_name, $TextEdit.text)

func set_hint(value):
	$Hint.text = str(value)

func set_value(value):
	$TextEdit.text = str(value)
