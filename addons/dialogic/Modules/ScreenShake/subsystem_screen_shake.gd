extends DialogicSubsystem

## Subsystem that manages screen shaking.


## Whenever a horizontal screen shake is started, this signal is emitted and
## contains a dictionary with the following keys: [br]
## [br]
## Key          |   Value Type  | Value [br]
## ------------ | ------------- | ----- [br]
## `amplitude`  | [type float]  | The strength of the screen shake. [br]
## `frequency`  | [type float]  | The speed of the screen shake. [br]
## `fade`       | [type float]  | The time the fade animation will take. Leave at 0 for instant change. [br]
## `duration`   | [type float]  | The time the screen should shake for (excludes fade time). [br]
signal shake_horizontal_started(info: Dictionary)

## Whenever a horizontal screen shake has finished, this signal is emitted.
signal shake_horizontal_finished()

## Whenever a vertical screen shake is started, this signal is emitted and
## contains a dictionary with the following keys: [br]
## [br]
## Key          |   Value Type  | Value [br]
## ------------ | ------------- | ----- [br]
## `amplitude`  | [type float]  | The strength of the screen shake. [br]
## `frequency`  | [type float]  | The speed of the screen shake. [br]
## `fade`       | [type float]  | The time the fade animation will take. Leave at 0 for instant change. [br]
## `duration`   | [type float]  | The time the screen should shake for (excludes fade time). [br]
signal shake_vertical_started(info: Dictionary)

## Whenever a vertical screen shake has finished, this signal is emitted.
signal shake_vertical_finished()

#region STATE
####################################################################################################

func clear_game_state(clear_flag:=Dialogic.ClearFlags.FULL_CLEAR) -> void:
	update_shake_x()
	update_shake_y()


func load_game_state(load_flag:=LoadFlags.FULL_LOAD) -> void:
	if load_flag == LoadFlags.ONLY_DNODES:
		return
	var info: Dictionary = dialogic.current_state_info.get('screen_shake', {'x':{},'y':{}})
	if info['x'].is_empty() or info['x'].get('amplitude', 0.0) == 0.0:
		update_shake_x()
	else:
		update_shake_x(info['x'].amplitude, info['x'].frequency, info['x'].fade, info['x'].duration)
	if info['y'].is_empty() or info['y'].get('amplitude', 0.0) == 0.0:
		update_shake_y()
	else:
		update_shake_y(info['y'].amplitude, info['y'].frequency, info['y'].fade, info['y'].duration)

#endregion

#region MAIN METHODS
####################################################################################################

func update_shake_x(amplitude: float = 0.0, frequency: float = 0.0, fade: float = 0.0, duration: float = 0.0) -> void:
	var previous_settings = dialogic.current_state_info.get('screen_shake', {'x':{},'y':{}})

	if not dialogic.current_state_info.has('screen_shake'):
		dialogic.current_state_info['screen_shake'] = {'x':{},'y':{}}

	dialogic.current_state_info['screen_shake']['x'] = {
		'amplitude': amplitude,
		'frequency': frequency,
		'fade': fade,
		'duration': duration,
	}

	shake_horizontal_started.emit(dialogic.current_state_info['screen_shake']['x'])

	var screen_shaker: DialogicNode_ScreenShaker
	if dialogic.has_subsystem('Styles'):
		screen_shaker = dialogic.Styles.get_first_node_in_layout('dialogic_screen_shaker')
	else:
		screen_shaker = get_tree().get_first_node_in_group('dialogic_screen_shaker')

	if not screen_shaker:
		return

	if previous_settings['x'].is_empty():
		screen_shaker.reset_x()

	if fade > 0.0:
		var current_amplitude := screen_shaker.material.get_shader_parameter('amplitude_x') as float
		var current_frequency := screen_shaker.material.get_shader_parameter('frequency_x') as float
		var tween := get_tree().create_tween()
		tween.tween_method(_tween_amplitude_x.bind(screen_shaker.material), current_amplitude, amplitude, fade)
		tween.set_parallel()
		tween.tween_method(_tween_frequency_x.bind(screen_shaker), current_frequency, frequency, fade)
		await tween.finished
	else:
		screen_shaker.material.set_shader_parameter('amplitude_x', amplitude)
		screen_shaker.update_frequency_x(frequency)

	if duration > 0.0 and amplitude > 0.0:
		await get_tree().create_timer(duration).timeout
	elif amplitude == 0.0:
		dialogic.current_state_info['screen_shake']['x'] = {}
		shake_horizontal_finished.emit()
		return
	else:
		return

	if fade > 0.0:
		var current_amplitude := screen_shaker.material.get_shader_parameter('amplitude_x') as float
		var current_frequency := screen_shaker.material.get_shader_parameter('frequency_x') as float
		var tween := get_tree().create_tween()
		tween.tween_method(_tween_amplitude_x.bind(screen_shaker.material), current_amplitude, 0.0, fade)
		tween.set_parallel()
		tween.tween_method(_tween_frequency_x.bind(screen_shaker), current_frequency, 0.0, fade)
		await tween.finished
	else:
		screen_shaker.material.set_shader_parameter('amplitude_x', 0.0)
		screen_shaker.update_frequency_x(frequency)

	dialogic.current_state_info['screen_shake']['x'] = {}
	shake_horizontal_finished.emit()


func update_shake_y(amplitude: float = 0.0, frequency: float = 0.0, fade: float = 0.0, duration: float = 0.0) -> void:
	var previous_settings = dialogic.current_state_info.get('screen_shake', {'x':{},'y':{}})
	dialogic.current_state_info['screen_shake']['y'] = {
		'amplitude': amplitude,
		'frequency': frequency,
		'fade': fade,
		'duration': duration,
	}

	shake_vertical_started.emit(dialogic.current_state_info['screen_shake']['y'])

	var screen_shaker: DialogicNode_ScreenShaker
	if dialogic.has_subsystem('Styles'):
		screen_shaker = dialogic.Styles.get_first_node_in_layout('dialogic_screen_shaker')
	else:
		screen_shaker = get_tree().get_first_node_in_group('dialogic_screen_shaker')

	if not screen_shaker:
		return

	if previous_settings['y'].is_empty():
		screen_shaker.reset_y()

	if fade > 0.0:
		var current_amplitude := screen_shaker.material.get_shader_parameter('amplitude_y') as float
		var current_frequency := screen_shaker.material.get_shader_parameter('frequency_y') as float
		var tween := get_tree().create_tween()
		tween.tween_method(_tween_amplitude_y.bind(screen_shaker.material), current_amplitude, amplitude, fade)
		tween.set_parallel()
		tween.tween_method(_tween_frequency_y.bind(screen_shaker), current_frequency, frequency, fade)
		await tween.finished
	else:
		screen_shaker.material.set_shader_parameter('amplitude_y', amplitude)
		screen_shaker.update_frequency_y(frequency)

	if duration > 0.0 and amplitude > 0.0:
		await get_tree().create_timer(duration).timeout
	elif amplitude == 0.0:
		dialogic.current_state_info['screen_shake']['y'] = {}
		shake_vertical_finished.emit()
		return
	else:
		return

	if fade > 0.0:
		var current_amplitude := screen_shaker.material.get_shader_parameter('amplitude_y') as float
		var current_frequency := screen_shaker.material.get_shader_parameter('frequency_y') as float
		var tween := get_tree().create_tween()
		tween.tween_method(_tween_amplitude_y.bind(screen_shaker.material), current_amplitude, 0.0, fade)
		tween.set_parallel()
		tween.tween_method(_tween_frequency_y.bind(screen_shaker), current_frequency, 0.0, fade)
		await tween.finished
	else:
		screen_shaker.material.set_shader_parameter('amplitude_y', 0.0)
		screen_shaker.update_frequency_y(frequency)

	dialogic.current_state_info['screen_shake']['y'] = {}
	shake_vertical_finished.emit()

#endregion

func _tween_amplitude_x(value: float, material: ShaderMaterial) -> void:
	material.set_shader_parameter('amplitude_x', value)


func _tween_amplitude_y(value: float, material: ShaderMaterial) -> void:
	material.set_shader_parameter('amplitude_y', value)


func _tween_frequency_x(value: float, screen_shaker: DialogicNode_ScreenShaker) -> void:
	screen_shaker.update_frequency_x(value)


func _tween_frequency_y(value: float, screen_shaker: DialogicNode_ScreenShaker) -> void:
	screen_shaker.update_frequency_y(value)
