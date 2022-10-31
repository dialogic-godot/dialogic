@tool
extends Control

var property_name : String
@export var allow_string :bool = false
@export var step:float = 0.1
@export var enforce_step:bool = true
@export var min:float = 0
@export var max:float= 999
@export var value = 0
@export var suffix := ""
signal value_changed

func _ready():
	if $Value.text.is_empty():
		set_value(value)
	$Spin.icon = get_theme_icon("updown", "SpinBox")
	$Value.add_theme_stylebox_override('normal', get_theme_stylebox('normal', 'LineEdit'))
	$Value.add_theme_stylebox_override('focus', get_theme_stylebox('focus', 'LineEdit'))

func set_right_text(value):
	$RightText.text = str(value)
	$RightText.visible = !value.is_empty()

func set_left_text(value):
	$LeftText.text = str(value)
	$LeftText.visible = !value.is_empty()

func set_value(new_value) -> void:
	if new_value:
		_on_value_text_submitted(str(new_value))
	else:
		_on_value_text_submitted(str(value))
	
func get_value():
	return value
	
func use_timestamp_mode():
	step = 0.1
	suffix = ' sec'
	max = 9999 #2.7 hours. Enough, or is more needed?

func use_float_mode():
	step = 0.1
	suffix = ""
	enforce_step = false

func use_int_mode():
	step = 1
	suffix = ""

func use_decibel_mode():
	max = 6
	suffix = "dB"
	min = -80

func set_max_value(value):
	max = value
	
func set_min_value(value):
	min = value

func _on_spin_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.position.y < size.y/2.0:
			_on_value_text_submitted(str(value+step))
		else:
			_on_value_text_submitted(str(value-step))


func _on_value_text_submitted(new_text):
	new_text = new_text.trim_suffix(suffix)
	if new_text.is_valid_float():
		var temp:float = min(max(new_text.to_float(), min), max)
		if !enforce_step or temp/step == round(temp/step):
			value = temp
	elif allow_string:
		value = new_text
	$Value.text = str(value)+suffix
	value_changed.emit(property_name, value)


func _on_value_focus_exited():
	_on_value_text_submitted($Value.text)
