extends RefCounted
## This class holds the settings for the Auto-Advance feature.
## Changing the variables will alter the behaviour of Auto-Advance.
##
## Auto-Advance must be implemented per event.
class_name DialogicAutoAdvance

signal autoadvance
signal autoadvance_changed(enabled: bool)

var enabled := false
var autoadvance_timer := Timer.new()


func _init() -> void:
	Dialogic.Input.add_child(autoadvance_timer)
	autoadvance_timer.one_shot = true
	autoadvance_timer.timeout.connect(_on_autoadvance_timer_timeout)
	autoadvance_changed.connect(_on_autoadvance_enabled_change)

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
		await Dialogic.get_tree().process_frame
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
	if (is_enabled and !is_autoadvancing() and Dialogic.current_state == Dialogic.States.IDLE and not Dialogic.current_state_info.get('text', '').is_empty()):
		start_autoadvance()

	# If auto-advance is disabled and we are auto-advancing,
	# we want to cancel the auto-advance mode.
	elif !is_enabled and is_autoadvancing():
		Dialogic.Input.stop()
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
	if not Dialogic.current_state_info.has('autoadvance'):
		Dialogic.current_state_info['autoadvance'] = {
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
	return Dialogic.current_state_info['autoadvance']


## Updates the [member _autoadvance_enabled] variable to properly check if the value has changed.
## If it changed, emits the [member autoadvance_changed] signal.
func _emit_autoadvance_enabled() -> void:
	var old_autoadvance_state = enabled
	enabled = is_autoadvance_enabled()

	if old_autoadvance_state != enabled:
		autoadvance_changed.emit(enabled)


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
