@tool
class_name DialogicVisualEditorFieldNumber extends DialogicVisualEditorField

## Event block field for integers and floats. Improved version of the native spinbox.

@export var allow_string :bool = false
@export var step:float = 0.1
@export var enforce_step:bool = true
@export var min:float = 0
@export var max:float= 999
@export var value = 0.0
@export var affix:String = ""
@export var suffix:String = ""

var _is_holding_button : bool = false #For handling incrementing while holding key or click

#region MAIN METHODS
################################################################################

func _ready() -> void:
	if %Value.text.is_empty():
		set_value(value)
	update_suffix(suffix)
	update_affix(affix)

func _load_display_info(info:Dictionary) -> void:
	match info.get('mode', 0):
		0: #FLOAT
			use_float_mode(info.get('step', 0.1))
		1: #INT
			use_int_mode(info.get('step', 1))
		2: #DECIBLE:
			use_decibel_mode(info.get('step', step))
	
	for option in info.keys():
		match option:
			'min': min = info[option]
			'max': max = info[option]
			'affix': update_affix(info[option])
			'suffix': update_suffix(info[option])
			'step': 
				enforce_step = true
				step = info[option]
			'hide_step_button': %Spin.hide()

func _set_value(new_value:Variant) -> void:
	_on_value_text_submitted(str(new_value), true)
	%Value.tooltip_text = tooltip_text

func _autofocus():
	%Value.grab_focus()

func get_value() -> float:
	return value

func use_float_mode(value_step: float = 0.1) -> void:
	step = value_step
	update_suffix("")
	enforce_step = false

func use_int_mode(value_step: float = 1) -> void:
	step = value_step
	update_suffix("")
	enforce_step = true

func use_decibel_mode(value_step: float = step) -> void:
	max = 6
	update_suffix("dB")
	min = -80

#endregion

#region UI FUNCTIONALITY
################################################################################
var _stop_button_holding : Callable = func(button : BaseButton) -> void:
	_is_holding_button = false
	if button.button_up.get_connections().find(_stop_button_holding):
		button.button_up.disconnect(_stop_button_holding)
	if button.focus_exited.get_connections().find(_stop_button_holding):
		button.focus_exited.disconnect(_stop_button_holding)
	if button.mouse_exited.get_connections().find(_stop_button_holding):
		button.mouse_exited.disconnect(_stop_button_holding)

func _holding_button(value_direction: int, button : BaseButton) -> void:
	if _is_holding_button: 
		return
	if _stop_button_holding.get_bound_arguments_count() > 0:
		_stop_button_holding.unbind(0)
	
	_is_holding_button = true
	
	#Ensure removal of our value changing routine when it shouldn't run anymore
	button.button_up.connect(_stop_button_holding.bind(button))
	button.focus_exited.connect(_stop_button_holding.bind(button))
	button.mouse_exited.connect(_stop_button_holding.bind(button))
	
	await get_tree().create_timer(0.6, true, false, true).timeout
	
	var change_speed : float = 0.25
	
	while(_is_holding_button == true):
		await get_tree().create_timer(change_speed).timeout
		change_speed = maxf(0.05, change_speed - 0.01)
		_on_value_text_submitted(str(value+(step * value_direction)))

func update_affix(to_affix:String) -> void:
	affix = to_affix
	%Affix.text = affix

func update_suffix(to_suffix:String) -> void:
	suffix = to_suffix
	%Suffix.text = suffix
#endregion

#region SIGNAL METHODS
################################################################################
func _on_gui_input(event : InputEvent) -> void:
	if event.is_action('ui_up') and event.get_action_strength('ui_up') > 0.5:
		_on_value_text_submitted(str(value+step))
	elif event.is_action('ui_down') and event.get_action_strength('ui_down') > 0.5:
		_on_value_text_submitted(str(value-step))

func _on_increment_button_down(button : NodePath) -> void:
	_on_value_text_submitted(str(value+step))
	_holding_button(1.0, get_node(button) as BaseButton)

func _on_decrement_button_down(button : NodePath) -> void:
	_on_value_text_submitted(str(value-step))
	_holding_button(-1.0, get_node(button) as BaseButton)

func _on_value_text_submitted(new_text:String, no_signal:= false) -> void:
	if new_text.is_valid_float():
		var temp: float = min(max(new_text.to_float(), min), max)
		if !enforce_step:
			value = temp
		else:
			value = snapped(temp, step)
	elif allow_string:
		value = new_text
	%Value.text = str(value)
	if not no_signal:
		value_changed.emit(property_name, value)
	# Visually disable Up or Down arrow when limit is reached to better indicate a limit has been hit
	%Spin/Decrement.disabled = value <= min
	%Spin/Increment.disabled = value >= max

# If Affix or Suffix clicked, select the actual value box instead and move the Carat to the closest side.
func _on_sublabel_clicked(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mousePos = get_global_mouse_position()
		mousePos.x -= get_minimum_size().x / 2
		if mousePos.x > global_position.x:
			(%Value as LineEdit).caret_column = (%Value as LineEdit).text.length()
		else:
			(%Value as LineEdit).caret_column = 0
		(%Value as LineEdit).grab_focus()

func _on_value_focus_exited() -> void:
	_on_value_text_submitted(%Value.text)

#endregion
