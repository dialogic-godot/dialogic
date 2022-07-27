tool
extends HBoxContainer

const max_value:float = 9999.0

var property_name
signal value_changed

func set_value(value):
	$StartValue.set_value(value.get("start"))
	$StopValue.set_value(value.get("stop"))
	$StopValue.set_min_value($StartValue.Value.value + 0.1)

# Called when the node enters the scene tree for the first time.
func _ready():
	$StartValue.use_float_mode()
	$StartValue.set_max_value(max_value - 0.1)
	$StartValue.set_right_text("sec")
	$StartValue.connect("value_changed", self,  'value_changed')
	$StopValue.use_float_mode()
	$StopValue.set_min_value(0.1)
	$StopValue.set_max_value(max_value)
	$StopValue.set_right_text("sec")
	$StopValue.connect("value_changed", self,  'value_changed')
	
func value_changed(property_name, value):
	$StopValue.set_min_value($StartValue.Value.value + 0.1)
	emit_signal("value_changed", property_name, {"start":$StartValue.value, "stop":$StopValue.value})
