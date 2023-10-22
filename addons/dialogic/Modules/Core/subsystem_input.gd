extends DialogicSubsystem

## Subsystem that handles input, autoadvance & skipping.


signal dialogic_action_priority
signal dialogic_action
signal autoadvance
signal autoadvance_changed(enabled: bool)

var _autoadvance_enabled = false
var autoadvance_timer := Timer.new()
var input_block_timer := Timer.new()

var action_was_consumed := false

#region SUBSYSTEM METHODS
func clear_game_state(clear_flag:=Dialogic.ClearFlags.FULL_CLEAR) -> void:
	set_autoadvance_system(ProjectSettings.get_setting('dialogic/text/autoadvance_enabled', false))
	var autoadvance_info := get_autoadvance_info()
	autoadvance_info['fixed_delay'] = ProjectSettings.get_setting('dialogic/text/autoadvance_fixed_delay', 1)
	autoadvance_info['per_word_delay'] = ProjectSettings.get_setting('dialogic/text/autoadvance_per_word_delay', 0)
	autoadvance_info['per_character_delay'] = ProjectSettings.get_setting('dialogic/text/autoadvance_per_character_delay', 0.1)
	autoadvance_info['ignored_characters_enabled'] = ProjectSettings.get_setting('dialogic/text/autoadvance_ignored_characters_enabled', true)
	autoadvance_info['ignored_characters'] = ProjectSettings.get_setting('dialogic/text/autoadvance_ignored_characters', {})
	set_manualadvance(true)

func pause() -> void:
	autoadvance_timer.paused = true
	input_block_timer.paused = true


func resume() -> void:
	autoadvance_timer.paused = false
	input_block_timer.paused = false

#endregion

#region MAIN METHODS

func handle_input():
	if Dialogic.paused or is_input_blocked():
		return

	# We want to stop auto-advancing that cancels on user inputs.
	if (!action_was_consumed and is_autoadvance_enabled()
			and get_autoadvance_info()['waiting_for_user_input']):
		set_autoadvance_until_user_input(false)
		return

	dialogic_action_priority.emit()

	if action_was_consumed:
		action_was_consumed = false
		return

	dialogic_action.emit()


## Unhandled Input is used for all NON-Mouse based inputs.
func _unhandled_input(event:InputEvent) -> void:
	if Input.is_action_pressed(ProjectSettings.get_setting('dialogic/text/input_action', 'dialogic_default_action')):
		if event is InputEventMouse:
			return
		handle_input()


## Input is used for all mouse based inputs. 
## If any DialogicInputNode is present this won't do anything (because that node handles MouseInput then).
func _input(event:InputEvent) -> void:
	if Input.is_action_pressed(ProjectSettings.get_setting('dialogic/text/input_action', 'dialogic_default_action')):
		if not event is InputEventMouse or get_tree().get_nodes_in_group('dialogic_input').any(func(node):return node.is_visible_in_tree()):
			return
		handle_input()


func is_input_blocked() -> bool:
	return input_block_timer.time_left > 0.0


func block_input(time:=0.1) -> void:
	if time > 0:
		input_block_timer.stop()
		input_block_timer.wait_time = time
		input_block_timer.start()


func _ready() -> void:
	await get_parent().ready
	add_child(autoadvance_timer)
	autoadvance_timer.one_shot = true
	autoadvance_timer.timeout.connect(_on_autoadvance_timer_timeout)
	autoadvance_changed.connect(_on_autoadvance_enabled_change)
	
	Dialogic.Settings.connect_to_change('autoadvance_delay_modifier', _update_autoadvance_delay_modifier)

	add_child(input_block_timer)
	input_block_timer.one_shot = true

func stop() -> void:
	autoadvance_timer.stop()
	input_block_timer.stop()

#endregion

#region AUTOADVANCE INTERNALS

func start_autoadvance() -> void:
	if not is_autoadvance_enabled():
		return
	
	var delay := _calculate_autoadvance_delay(
				get_autoadvance_info(), 
				Dialogic.current_state_info['text_parsed'])
	if delay == 0:
		_on_autoadvance_timer_timeout()
	else:
		await get_tree().process_frame
		autoadvance_timer.start(delay)


## Calculates the autoadvance-time based on settings and text.
## 
## Takes into account:
## - temporary delay time override
## - delay per word
## - delay per character
## - fixed delay
## - text time taken
## - autoadvance delay modifier 
## - voice audio
func _calculate_autoadvance_delay(info:Dictionary, text:String="") -> float:
	var delay := 0.0
	
	# Check for temporary time override
	if info['override_delay_for_current_event'] >= 0:
		delay = info['override_delay_for_current_event']
	else:
		# Add per word and per character delay
		delay = _calculate_per_word_delay(text, info) + _calculate_per_character_delay(text, info)
		delay *= Dialogic.Settings.get_setting('autoadvance_delay_modifier', 1)
		# Apply fixed delay last, so it's not affected by the delay modifier
		delay += info['fixed_delay']
		
		delay = max(0, delay)
	
	# Wait for the voice clip (if longer than the current delay)
	if info['await_playing_voice'] and Dialogic.has_subsystem('Voice') and Dialogic.Voice.is_running():
		delay = max(delay, Dialogic.Voice.get_remaining_time())
	
	return delay


## Checks how many words can be found by separating the text by whitespace.
##   (Uses ` ` aka SPACE right now, could be extended in the future)
func _calculate_per_word_delay(text: String, info:Dictionary) -> float:
	return float(text.split(' ', false).size() * info['per_word_delay'])


## Checks how many characters can be found by iterating each letter.
func _calculate_per_character_delay(text: String, info:Dictionary) -> float:
	var per_character_delay: float = info['per_character_delay']
	var calculated_delay: float = 0

	if per_character_delay > 0:
		# If we have characters to ignore, we will iterate each letter.
		if info['ignored_characters_enabled']:
			for character in text:
				if character in info['ignored_characters']:
					continue
				calculated_delay += per_character_delay

		# Otherwise, we can just multiply the length of the text by the delay.
		else:
			calculated_delay = text.length() * per_character_delay

	return calculated_delay


func _on_autoadvance_timer_timeout() -> void:
	autoadvance.emit()
	autoadvance_timer.stop()


## Switches the auto-advance mode on or off based on [param is_enabled].
func _on_autoadvance_enabled_change(is_enabled: bool) -> void:
	# If auto-advance is enabled and we are not auto-advancing yet,
	# we will initiate the auto-advance mode.
	if (is_enabled and !is_autoadvancing() and Dialogic.current_state == Dialogic.States.IDLE and not Dialogic.current_state_info['text'].is_empty()):
		start_autoadvance()

	# If auto-advance is disabled and we are auto-advancing,
	# we want to cancel the auto-advance mode.
	elif !is_enabled and is_autoadvancing():
		stop()
#endregion

#region AUTOADVANCE HELPERS
func is_autoadvancing() -> bool:
	return !autoadvance_timer.is_stopped()


func get_autoadvance_time_left() -> float:
	return autoadvance_timer.time_left


func get_autoadvance_time() -> float:
	return autoadvance_timer.wait_time


## Returns whether autoadvance is currently considered enabled.
## Autoadvance is considered on if any of these flags is true:
## - waiting_for_user_input (becomes false on any dialogic input action)
## - waiting_for_next_event (becomes false on each text event)
## - waiting_for_system (becomes false only when disabled via code)
## 
## All three can be set with dedicated methods.
func is_autoadvance_enabled() -> bool:
	return (get_autoadvance_info()['waiting_for_next_event']
		or get_autoadvance_info()['waiting_for_user_input']
		or get_autoadvance_info()['waiting_for_system'])


## Fetches all Auto-Advance settings.
## If they don't exist, returns the default settings.
## The key's values will be changed upon setting them.
func get_autoadvance_info() -> Dictionary:
	if not dialogic.current_state_info.has('autoadvance'):
		dialogic.current_state_info['autoadvance'] = {
		'waiting_for_next_event' : false,
		'waiting_for_user_input' : false,
		'waiting_for_system' : false,
		'fixed_delay' : 1,
		'per_word_delay' : 0,
		'per_character_delay' : 0.1,
		'ignored_characters_enabled' : false,
		'ignored_characters' : {},
		'override_delay_for_current_event' : -1,
		'await_playing_voice' : true,
		}
	return dialogic.current_state_info['autoadvance']


## Updates the [member _autoadvance_enabled] variable to properly check if the value has changed.
## If it changed, emits the [member autoadvance_changed] signal.
func _emit_autoadvance_enabled() -> void:
	var old_autoadvance_state = _autoadvance_enabled
	_autoadvance_enabled = is_autoadvance_enabled()

	if old_autoadvance_state != _autoadvance_enabled:
		autoadvance_changed.emit(_autoadvance_enabled)


## Sets the autoadvance waiting_for_user_input flag to [param enabled].
func set_autoadvance_until_user_input(enabled: bool) -> void:
	var info := get_autoadvance_info()
	info['waiting_for_user_input'] = enabled
	
	_emit_autoadvance_enabled()


## Sets the autoadvance waiting_for_system flag to [param enabled].
func set_autoadvance_system(enabled: bool) -> void:
	var info := get_autoadvance_info()
	info['waiting_for_system'] = enabled
	
	_emit_autoadvance_enabled()


## Sets the autoadvance waiting_for_next_event flag to [param enabled].
func set_autoadvance_until_next_event(enabled: bool) -> void:
	var info := get_autoadvance_info()
	info['waiting_for_next_event'] = enabled
	
	_emit_autoadvance_enabled()


func _update_autoadvance_delay_modifier(delay_modifier: float) -> void:
	var info: Dictionary = get_autoadvance_info()
	info['delay_modifier'] = delay_modifier



func set_autoadvance_override_delay_for_current_event(delay_time := -1.0) -> void:
	var info := get_autoadvance_info()
	info['override_delay_for_current_event'] = delay_time


## Returns the progress of the auto-advance timer on a scale between 0 and 1.
## The higher the value, the closer the timer is to finishing.
## If auto-advancing is disabled, returns -1.
func get_autoadvance_progress() -> float:
	if !is_autoadvancing():
		return -1

	var total_time: float = get_autoadvance_time()
	var time_left: float = get_autoadvance_time_left()
	var progress: float = (total_time - time_left) / total_time

	return progress
#endregion

#region MANUAL ADVANCE

func set_manualadvance(enabled:=true, temp:= false) -> void:
	if !dialogic.current_state_info.has('manual_advance'):
		dialogic.current_state_info['manual_advance'] = {'enabled':false, 'temp_enabled':false}
	if temp:
		dialogic.current_state_info['manual_advance']['temp_enabled'] = enabled
	else:
		dialogic.current_state_info['manual_advance']['enabled'] = enabled


func is_manualadvance_enabled() -> bool:
	return dialogic.current_state_info['manual_advance']['enabled'] and dialogic.current_state_info['manual_advance'].get('temp_enabled', true)

#endregion

#region TEXT EFFECTS

func effect_input(text_node:Control, skipped:bool, argument:String) -> void:
	if skipped:
		return
	Dialogic.Text.show_next_indicators()
	await Dialogic.Input.dialogic_action_priority
	Dialogic.Text.hide_next_indicators()
	Dialogic.Input.action_was_consumed = true


func effect_noskip(text_node:Control, skipped:bool, argument:String) -> void:
	Dialogic.Text.set_text_reveal_skippable(false, true)
	set_manualadvance(false, true)
	effect_autoadvance(text_node, skipped, argument)


func effect_autoadvance(text_node: Control, skipped:bool, argument:String) -> void:
	if argument.ends_with('?'):
		argument = argument.trim_suffix('?')
	else:
		set_autoadvance_until_next_event(true)
	
	if argument.is_valid_float():
		set_autoadvance_override_delay_for_current_event(float(argument))
#endregion
