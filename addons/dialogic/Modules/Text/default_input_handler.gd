@tool
extends Node

signal dialogic_action_priority
signal dialogic_action
signal autoadvance
signal autoskip

var autoadvance_timer := Timer.new()
var autoskip_timer := Timer.new()
var input_block_timer := Timer.new()
var skip_delay: float = ProjectSettings.get_setting('dialogic/text/skippable_delay', 0.1)
var _autoskip_timer_left: float = 0.0

var action_was_consumed := false

################################################################################
## 						INPUT
################################################################################
func _input(event: InputEvent) -> void:
	if event.is_action_pressed(ProjectSettings.get_setting('dialogic/text/input_action', 'dialogic_default_action')):

		if Dialogic.paused or is_input_blocked():
			return

		if !action_was_consumed:
			# We want to stop auto-advancing that cancels on user inputs.
			if (Dialogic.Text.is_autoadvance_enabled()
				and Dialogic.Text.get_autoadvance_info()['waiting_for_user_input']):
				Dialogic.Text.set_autoadvance_until_user_input(false)
				action_was_consumed = true

			# We want to stop auto-skipping if it's enabled, we are listening
			# to user inputs, and it's not instant skipping.
			if (Dialogic.Text.get_autoskip_info()['disable_on_user_input']
				and not Dialogic.Text.get_autoskip_info()['is_instant']
				and Dialogic.Text.is_autoskip_enabled()):
				Dialogic.Text.cancel_autoskip()
				action_was_consumed = true

		dialogic_action_priority.emit()

		if action_was_consumed:
			action_was_consumed = false
			return

		dialogic_action.emit()


func is_input_blocked() -> bool:
	return input_block_timer.time_left > 0.0


func block_input(time:=skip_delay) -> void:
	if time > 0:
		input_block_timer.stop()
		input_block_timer.wait_time = time
		input_block_timer.start()


####################################################################################################
##								AUTO-ADVANCING
####################################################################################################

func start_autoadvance() -> void:
	if not Dialogic.Text.is_autoadvance_enabled():
		return

	var delay := _calculate_autoadvance_delay(
				Dialogic.Text.get_autoadvance_info(),
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

func _on_autoskip_timer_timeout() -> void:
	autoskip.emit()
	autoskip_timer.stop()


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

func _on_autoskip_enabled_change(is_enabled: bool) -> void:
	if not Dialogic.has_subsystem('History'):
		return

	if not Dialogic.History.was_last_event_already_read:
		return

	# If instant skipping is enabled while we are on an event already,
	# we will move to the next event.
	if is_enabled:
		skip()

## This method will advance the timeline based on Auto-Skip settings.
## The state, whether Auto-Skip is enabled, is ignored.
## However, the setting [code]is_instant[/code] is respected.
func skip() -> void:
	var info: Dictionary = Dialogic.Text.get_autoskip_info()

	# If we are instant skipping, we will emit the signal and return.
	if (info['is_instant']
	and Dialogic.has_subsystem('History')
	and Dialogic.History.was_last_event_already_read):
		autoskip.emit()
		return

	var auto_skip_delay: float = info['time_per_event']
	_autoskip_timer_left = auto_skip_delay
	set_process(true)

func is_autoadvancing() -> bool:
	return !autoadvance_timer.is_stopped()


func get_autoadvance_time_left() -> float:
	return autoadvance_timer.time_left


func get_autoadvance_time() -> float:
	return autoadvance_timer.wait_time


func _ready() -> void:
	add_child(autoadvance_timer)
	autoadvance_timer.one_shot = true
	autoadvance_timer.timeout.connect(_on_autoadvance_timer_timeout)
	Dialogic.Text.autoadvance_changed.connect(_on_autoadvance_enabled_change)

	add_child(autoskip_timer)
	autoskip_timer.one_shot = true
	autoskip_timer.timeout.connect(_on_autoskip_timer_timeout)
	Dialogic.Text.autoskip_changed.connect(_on_autoskip_enabled_change)

	add_child(input_block_timer)
	input_block_timer.one_shot = true

	# We use the process method to count down the auto-skip timer.
	set_process(false)


func pause() -> void:
	autoadvance_timer.paused = true
	autoskip_timer.paused = true
	input_block_timer.paused = true


func stop() -> void:
	autoadvance_timer.stop()
	input_block_timer.stop()


func resume() -> void:
	autoadvance_timer.paused = false
	autoskip_timer.paused = false
	input_block_timer.paused = false

################################################################################
## 						AUTO-SKIP
################################################################################

## Handles fine-grained Auto-Skip logic.
## The [method _process] method allows for a more precise timer than the
## [Timer] class.
func _process(delta):
	if _autoskip_timer_left > 0:
		_autoskip_timer_left -= delta

		if _autoskip_timer_left <= 0:
			_on_autoskip_timer_timeout()

