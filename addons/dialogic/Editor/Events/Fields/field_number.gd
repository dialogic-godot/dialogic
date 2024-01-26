@tool
extends DialogicVisualEditorField

## Event block field for integers and floats. Improved version of the native spinbox.

@export var allow_string :bool = false
@export var step:float = 0.1
@export var enforce_step:bool = true
@export var min:float = 0
@export var max:float= 999
@export var value = 0
@export var suffix := ""


#region MAIN METHODS
################################################################################

func _ready() -> void:
	if $Value.text.is_empty():
		set_value(value)
	$Spin.icon = get_theme_icon("updown", "SpinBox")


func _load_display_info(info:Dictionary) -> void:
	match info.get('mode', 0):
		0: #FLOAT
			use_float_mode()
		1: #INT
			use_int_mode()
		2: #DECIBLE:
			use_decibel_mode()

	max = info.get('max', max)
	min = info.get('min', min)


func _set_value(new_value:Variant) -> void:
	_on_value_text_submitted(str(new_value), true)
	$Value.tooltip_text = tooltip_text


func _autofocus():
	$Value.grab_focus()


func get_value() -> float:
	return value


func use_float_mode() -> void:
	step = 0.1
	suffix = ""
	enforce_step = false


func use_int_mode() -> void:
	step = 1
	suffix = ""
	enforce_step = true


func use_decibel_mode() -> void:
	max = 6
	suffix = "dB"
	min = -80

#endregion


#region SIGNAL METHODS
################################################################################
func _on_spin_gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.position.y < size.y/2.0:
			_on_value_text_submitted(str(value+step))
		else:
			_on_value_text_submitted(str(value-step))


func _on_value_text_submitted(new_text:String, no_signal:= false) -> void:
	new_text = new_text.trim_suffix(suffix)
	if new_text.is_valid_float():
		var temp: float = min(max(new_text.to_float(), min), max)
		if !enforce_step or is_equal_approx(temp/step, round(temp/step)):
			value = temp
		else:
			value = snapped(temp, step)
	elif allow_string:
		value = new_text
	$Value.text = str(value)+suffix
	if not no_signal:
		value_changed.emit(property_name, value)


func _on_value_focus_exited() -> void:
	_on_value_text_submitted($Value.text)

#endregion
