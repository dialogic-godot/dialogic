@tool
extends Control

## Event block field for integers and floats. Improved version of the native spinbox.

signal value_changed
var property_name : String

@export var allow_string :bool = false
@export var step:float = 0.1
@export var enforce_step:bool = true
@export var min:float = 0
@export var max:float= 999
@export var value = 0
@export var suffix := ""

func _ready():
	if $Value.text.is_empty():
		set_value(value)
	$Spin.icon = get_theme_icon("updown", "SpinBox")
	$Value.add_theme_stylebox_override('normal', get_theme_stylebox('normal', 'LineEdit'))
	$Value.add_theme_stylebox_override('focus', get_theme_stylebox('focus', 'LineEdit'))

func set_value(new_value) -> void:
	_on_value_text_submitted(str(new_value))
	$Value.tooltip_text = tooltip_text
	
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
		if !enforce_step or is_equal_approx(temp/step, round(temp/step)):
			value = temp
		else:
			value = snapped(temp, step)
	elif allow_string:
		value = new_text
	$Value.text = str(value)+suffix
	value_changed.emit(property_name, value)


func _on_value_focus_exited():
	_on_value_text_submitted($Value.text)


func take_autofocus():
	$Value.grab_focus()
