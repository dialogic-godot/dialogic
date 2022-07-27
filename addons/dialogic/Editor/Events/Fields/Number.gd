tool
extends Control

var property_name : String
signal value_changed

func _ready():
	$Value.connect("value_changed", self,  'value_changed')


func value_changed(value):
	emit_signal("value_changed", property_name, $Value.value)


func set_right_text(value):
	$RightText.text = str(value)

func set_left_text(value):
	$LeftText.text = str(value)

func set_value(value):
	$Value.value = value

func use_float_mode():
	$Value.step = 0.001
	$Value.suffix = ""

func use_int_mode():
	$Value.step = 1
	$Value.suffix = ""

func use_decibel_mode():
	$Value.max_value = 6
	$Value.suffix = "dB"
	$Value.min_value = -80

func set_max_value(value):
	$Value.max_value = value
	
func set_min_value(value):
	$Value.min_value = value
