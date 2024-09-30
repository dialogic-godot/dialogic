class_name DialogicAutoAdvance
extends RefCounted
## This class holds the settings for the Auto-Advance feature.
## Changing the variables will alter the behaviour of Auto-Advance.
##
## Auto-Advance is a feature that automatically advances the timeline after
## a player-specific amount of time.
## This is useful for visual novels that want the player to read the text
## without having to press.
##
## Unlike [class DialogicAutoSkip], Auto-Advance uses multiple enable flags,
## allowing to track the different instances that enabled Auto-Advance.
## For instance, if a timeline event forces Auto-Advance to be enabled and later
## disables it, the Auto-Advance will still be enabled if the player didn't
## cancel it.

signal autoadvance
signal toggled(enabled: bool)

var autoadvance_timer := Timer.new()

var fixed_delay: float = 1.0
var delay_modifier: float = 1.0

var per_word_delay: float = 0.0
var per_character_delay: float = 0.1

var ignored_characters_enabled := false
var ignored_characters := {}

var await_playing_voice := true

var override_delay_for_current_event: float = -1.0

## Private variable to track the last Auto-Advance state.
## This will be used to emit the [signal toggled] signal.
var _last_enable_state := false

## If true, Auto-Advance will be active until the next event.
##
## Use this flag to create a temporary Auto-Advance mode.
## You can utilise [variable override_delay_for_current_event] to set a
## temporary Auto-Advance delay for this event.
##
## Stacks with [variable enabled_forced] and [variable enabled_until_user_input].
var enabled_until_next_event := false :
	set(enabled):
		enabled_until_next_event = enabled
		_try_emit_toggled()

## If true, Auto-Advance will stay enabled until this is set to false.
##
## This boolean can be used to create an automatic text display.
##
## Stacks with [variable enabled_until_next_event] and [variable enabled_until_user_input].
var enabled_forced := false :
	set(enabled):
		enabled_forced = enabled
		_try_emit_toggled()

## If true, Auto-Advance will be active until the player presses a button.
##
## Use this flag when the player wants to enable Auto-Advance.
##
## Stacks with [variable enabled_forced] and [variable enabled_until_next_event].
var enabled_until_user_input := false :
	set(enabled):
		enabled_until_user_input = enabled
		_try_emit_toggled()


func _init() -> void:
	DialogicUtil.autoload().Inputs.add_child(autoadvance_timer)
	autoadvance_timer.one_shot = true
	autoadvance_timer.timeout.connect(_on_autoadvance_timer_timeout)
	toggled.connect(_on_toggled)

	enabled_forced = ProjectSettings.get_setting('dialogic/text/autoadvance_enabled', false)
	fixed_delay = ProjectSettings.get_setting('dialogic/text/autoadvance_fixed_delay', 1)
	per_word_delay = ProjectSettings.get_setting('dialogic/text/autoadvance_per_word_delay', 0)
	per_character_delay = ProjectSettings.get_setting('dialogic/text/autoadvance_per_character_delay', 0.1)
	ignored_characters_enabled = ProjectSettings.get_setting('dialogic/text/autoadvance_ignored_characters_enabled', true)
	ignored_characters = ProjectSettings.get_setting('dialogic/text/autoadvance_ignored_characters', {})

#region AUTOADVANCE INTERNALS

func start() -> void:
	if not is_enabled():
		return

	var parsed_text: String = DialogicUtil.autoload().current_state_info['text_parsed']
	var delay := _calculate_autoadvance_delay(parsed_text)

	await DialogicUtil.autoload().get_tree().process_frame
	if delay == 0:
		_on_autoadvance_timer_timeout()
	else:
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
func _calculate_autoadvance_delay(text: String = "") -> float:
	var delay := 0.0

	# Check for temporary time override
	if override_delay_for_current_event >= 0:
		delay = override_delay_for_current_event
	else:
		# Add per word and per character delay
		delay = _calculate_per_word_delay(text) + _calculate_per_character_delay(text)

		delay *= delay_modifier
		# Apply fixed delay last, so it's not affected by the delay modifier
		delay += fixed_delay

		delay = max(0, delay)

	# Wait for the voice clip (if longer than the current delay)
	if await_playing_voice and DialogicUtil.autoload().has_subsystem('Voice') and DialogicUtil.autoload().Voice.is_running():
		delay = max(delay, DialogicUtil.autoload().Voice.get_remaining_time())

	return delay


## Checks how many words can be found by separating the text by whitespace.
##   (Uses ` ` aka SPACE right now, could be extended in the future)
func _calculate_per_word_delay(text: String) -> float:
	return float(text.split(' ', false).size() * per_word_delay)


## Checks how many characters can be found by iterating each letter.
func _calculate_per_character_delay(text: String) -> float:
	var calculated_delay: float = 0

	if per_character_delay > 0:
		# If we have characters to ignore, we will iterate each letter.
		if ignored_characters_enabled:
			for character in text:
				if character in ignored_characters:
					continue
				calculated_delay += per_character_delay

		# Otherwise, we can just multiply the length of the text by the delay.
		else:
			calculated_delay = text.length() * per_character_delay

	return calculated_delay


func _on_autoadvance_timer_timeout() -> void:
	autoadvance.emit()
	autoadvance_timer.stop()


## Switches the auto-advance mode on or off based on [param enabled].
func _on_toggled(enabled: bool) -> void:
	# If auto-advance is enabled and we are not auto-advancing yet,
	# we will initiate the auto-advance mode.
	if (enabled and !is_advancing()
	and DialogicUtil.autoload().current_state == DialogicGameHandler.States.IDLE
	and not DialogicUtil.autoload().current_state_info.get('text', '').is_empty()):
		start()

	# If auto-advance is disabled and we are auto-advancing,
	# we want to cancel the auto-advance mode.
	elif !enabled and is_advancing():
		DialogicUtil.autoload().Inputs.stop_timers()
#endregion

#region AUTOADVANCE HELPERS
func is_advancing() -> bool:
	return !autoadvance_timer.is_stopped()


func get_time_left() -> float:
	return autoadvance_timer.time_left


func get_time() -> float:
	return autoadvance_timer.wait_time


## Returns whether Auto-Advance is currently considered enabled.
## Auto-Advance uses three different enable flags:
## - enabled_until_user_input (becomes false on any dialogic input action)
## - enabled_until_next_event (becomes false on each text event)
## - enabled_forced (becomes false only when disabled via code)
##
## All three can be set with dedicated methods.
func is_enabled() -> bool:
	return (enabled_until_next_event
		or enabled_until_user_input
		or enabled_forced)


## Updates the [member _autoadvance_enabled] variable to properly check if the value has changed.
## If it changed, emits the [member toggled] signal.
func _try_emit_toggled() -> void:
	var old_autoadvance_state := _last_enable_state
	_last_enable_state = is_enabled()

	if old_autoadvance_state != _last_enable_state:
		toggled.emit(_last_enable_state)


## An internal method connected to changes on the Delay Modifier setting.
func _update_autoadvance_delay_modifier(delay_modifier_value: float) -> void:
	delay_modifier = delay_modifier_value


## Returns the progress of the auto-advance timer on a scale between 0 and 1.
## The higher the value, the closer the timer is to finishing.
## If auto-advancing is disabled, returns -1.
func get_progress() -> float:
	if !is_advancing():
		return -1

	var total_time: float = get_time()
	var time_left: float = get_time_left()
	var progress: float = (total_time - time_left) / total_time

	return progress
#endregion
