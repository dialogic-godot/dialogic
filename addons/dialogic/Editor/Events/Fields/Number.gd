tool
extends Control

var property_name : String
signal value_changed

func _ready():
	$Value.connect("value_changed", self,  'value_changed')


func value_changed(value):
	emit_signal("value_changed", property_name, $Value.value)


func set_hint(value):
	$Hint.text = str(value)

func set_value(value):
	$Value.value = str(value)
