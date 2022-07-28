tool
extends HBoxContainer

const max_value:float = 9999.0

var property_name
signal value_changed

func set_value(value):
	$StartValue.set_value(value.get("start"))
	$StopValue.set_value(value.get("stop"))
	$StopValue.set_min_value($StartValue.get_value() + 0.1)

func get_value():
	return {"start":$StartValue.get_value(), "stop":$StopValue.get_value()}

# Called when the node enters the scene tree for the first time.
func _ready():
	$StartValue.use_timestamp_mode()
	$StartValue.set_max_value(max_value - 0.1)
	$StartValue.connect("value_changed", self,  'value_changed')
	$StopValue.use_timestamp_mode()
	$StopValue.set_min_value(0.1)
	$StopValue.set_max_value(max_value)
	$StopValue.connect("value_changed", self,  'value_changed')
	
func value_changed(property_name, value):
	$StopValue.set_min_value($StartValue.get_value() + 0.1)
	emit_signal("value_changed", property_name, get_value())


