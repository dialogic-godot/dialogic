@tool
class_name DialogicVisualEditorFieldNumber
extends DialogicVisualEditorField

## Event block field for integers and floats. Improved version of the native spinbox.

@export_enum("Float", "Int", "Decible") var mode := 0 :
	set(new_mode):
		mode = new_mode
		match mode:
			0: use_float_mode() #FLOAT
			1: use_int_mode() #INT
			2: use_decibel_mode() #DECIBLE
@export var allow_string: bool = false
@export var step: float = 0.1
@export var enforce_step: bool = true
@export var min_value: float = -INF
@export var max_value: float = INF
@export var value = 0.0
@export var prefix: String = ""
@export var suffix: String = ""

var _is_holding_button: bool = false #For handling incrementing while holding key or click

#region MAIN METHODS
################################################################################

func _ready() -> void:
	if %Value.text.is_empty():
		set_value(value)

	update_prefix(prefix)
	update_suffix(suffix)


func _load_display_info(info: Dictionary) -> void:

	for option in info.keys():
		match option:
			'min': min_value = info[option]
			'max': max_value = info[option]
			'prefix': update_prefix(info[option])
			'suffix': update_suffix(info[option])
			'step':
				enforce_step = true
				step = info[option]
			'hide_step_button': %Spin.hide()

	mode = info.get('mode', mode)

func _set_value(new_value: Variant) -> void:
	_on_value_text_submitted(str(new_value), true)
	%Value.tooltip_text = tooltip_text


func _autofocus() -> void:
	%Value.grab_focus()


func get_value() -> float:
	return value


func use_float_mode() -> void:
	update_suffix("")
	enforce_step = false


func use_int_mode() -> void:
	update_suffix("")
	enforce_step = true


func use_decibel_mode() -> void:
	max_value = 6
	update_suffix("dB")
	min_value = -80

#endregion

#region UI FUNCTIONALITY
################################################################################
var _stop_button_holding: Callable = func(button: BaseButton) -> void:
	_is_holding_button = false
	if button.button_up.get_connections().find(_stop_button_holding):
		button.button_up.disconnect(_stop_button_holding)
	if button.focus_exited.get_connections().find(_stop_button_holding):
		button.focus_exited.disconnect(_stop_button_holding)
	if button.mouse_exited.get_connections().find(_stop_button_holding):
		button.mouse_exited.disconnect(_stop_button_holding)


func _holding_button(value_direction: int, button: BaseButton) -> void:
	if _is_holding_button:
		return
	if _stop_button_holding.get_bound_arguments_count() > 0:
		_stop_button_holding.unbind(0)

	_is_holding_button = true

	#Ensure removal of our value changing routine when it shouldn't run anymore
	button.button_up.connect(_stop_button_holding.bind(button))
	button.focus_exited.connect(_stop_button_holding.bind(button))
	button.mouse_exited.connect(_stop_button_holding.bind(button))

	var scene_tree: SceneTree = get_tree()
	var delay_timer_ms: int = 600

	#Instead of awaiting for the duration, await per-frame so we can catch any changes in _is_holding_button and exit completely
	while(delay_timer_ms > 0):
		if _is_holding_button == false:
			return
		var pre_time: int = Time.get_ticks_msec()
		await scene_tree.process_frame
		delay_timer_ms -= Time.get_ticks_msec() - pre_time

	var change_speed: float = 0.25

	while(_is_holding_button == true):
		await scene_tree.create_timer(change_speed).timeout
		change_speed = maxf(0.05, change_speed - 0.01)
		_on_value_text_submitted(str(value+(step * value_direction)))


func update_prefix(to_prefix: String) -> void:
	prefix = to_prefix
	%Prefix.visible = to_prefix != null and to_prefix != ""
	%Prefix.text = prefix


func update_suffix(to_suffix: String) -> void:
	suffix = to_suffix
	%Suffix.visible = to_suffix != null and to_suffix != ""
	%Suffix.text = suffix

#endregion

#region SIGNAL METHODS
################################################################################
func _on_gui_input(event: InputEvent) -> void:
	if event.is_action('ui_up') and event.get_action_strength('ui_up') > 0.5:
		_on_value_text_submitted(str(value+step))
	elif event.is_action('ui_down') and event.get_action_strength('ui_down') > 0.5:
		_on_value_text_submitted(str(value-step))


func _on_increment_button_down(button: NodePath) -> void:
	_on_value_text_submitted(str(value+step))
	_holding_button(1.0, get_node(button) as BaseButton)


func _on_decrement_button_down(button: NodePath) -> void:
	_on_value_text_submitted(str(value-step))
	_holding_button(-1.0, get_node(button) as BaseButton)


func _on_value_text_submitted(new_text: String, no_signal:= false) -> void:
	if new_text.is_empty() and not allow_string:
		new_text = "0.0"
	if new_text.is_valid_float():
		var temp: float = min(max(new_text.to_float(), min_value), max_value)
		if not enforce_step:
			value = temp
		else:
			value = snapped(temp, step)
	elif allow_string:
		value = new_text
	%Value.text = str(value).pad_decimals(
		max(
			len(str(float(step)-floorf(step)))-2,
			len(str(float(value)-floorf(value)))-2,))
	if not no_signal:
		value_changed.emit(property_name, value)
	# Visually disable Up or Down arrow when limit is reached to better indicate a limit has been hit
	%Spin/Decrement.disabled = value <= min_value
	%Spin/Increment.disabled = value >= max_value


# If prefix or suffix was clicked, select the actual value box instead and move the caret to the closest side.
func _on_sublabel_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mousePos: Vector2 = get_global_mouse_position()
		mousePos.x -= get_minimum_size().x / 2
		if mousePos.x > global_position.x:
			(%Value as LineEdit).caret_column = (%Value as LineEdit).text.length()
		else:
			(%Value as LineEdit).caret_column = 0
		(%Value as LineEdit).grab_focus()


func _on_value_focus_exited() -> void:
	_on_value_text_submitted(%Value.text)
	$Value_Panel.add_theme_stylebox_override('panel', get_theme_stylebox('panel', 'DialogicEventEdit'))


func _on_value_focus_entered() -> void:
	$Value_Panel.add_theme_stylebox_override('panel', get_theme_stylebox('focus', 'DialogicEventEdit'))
	%Value.select_all.call_deferred()

#endregion
