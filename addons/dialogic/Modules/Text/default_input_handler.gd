@tool
extends Node

signal dialogic_action_priority
signal dialogic_action
signal autoadvance

var autoadvance_timer := Timer.new()
var input_block_timer := Timer.new()
var skip_delay :float = ProjectSettings.get_setting('dialogic/text/skippable_delay', 0.1)

var action_was_consumed := false

################################################################################
## 						INPUT
################################################################################
func _input(event: InputEvent) -> void:
	if event.is_action_pressed(ProjectSettings.get_setting('dialogic/text/input_action', 'dialogic_default_action')):

		if Dialogic.paused or is_input_blocked():
			return

		# We want to stop auto-advancing that cancels on user inputs.
		if (!action_was_consumed
		and Dialogic.Text.get_autoadvance_info()['waiting_for_user_input']
		and Dialogic.Text.should_autoadvance()):
			Dialogic.Text.set_autoadvance_until_user_input(false)
			return

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
func _ready() -> void:
	add_child(autoadvance_timer)
	autoadvance_timer.one_shot = true
	autoadvance_timer.timeout.connect(_on_autoadvance_timer_timeout)
	Dialogic.Text.autoadvance_changed.connect(_on_autoadvance_enabled_change)

	add_child(input_block_timer)
	input_block_timer.one_shot = true


## Checks how many words can be found by separating the text by whitespace.
## The current whitespaces supported is the normal ` `.
## In the future, this could be extended.
func _calculate_per_word_delay(text: String) -> float:
	var per_word_delay :float = Dialogic.Text.get_autoadvance_info()['per_word_delay']

	var word_count :int = text.split(' ', false).size()
	var calculated_delay :float = word_count * per_word_delay

	return calculated_delay


## If a voice clip is still playing, returns the voice clip's play time left
## in seconds.
func _voice_play_time_left() -> float:
	var info: Dictionary = Dialogic.Text.get_autoadvance_info()

	if info['await_playing_voice'] and Dialogic.has_subsystem('Voice') and Dialogic.Voice.voice_player.is_playing():
		var stream_length: float = Dialogic.Voice.voice_player.stream.get_length()
		var playback_position: float = Dialogic.Voice.voice_player.get_playback_position()
		var remaining_playtime := stream_length - playback_position
		return remaining_playtime
	else:
		return 0.0


## Checks how many characters can be found by iterating each letter.
func _calculate_per_character_delay(text: String) -> float:
	var info: Dictionary = Dialogic.Text.get_autoadvance_info()
	var per_character_delay :float = info['per_character_delay']
	var calculated_delay :float = 0

	if per_character_delay > 0:
		var is_ignored_characters_enabled :bool = info['ignored_characters_enabled']

		# If we have characters to ignore, we will iterate each letter.
		if is_ignored_characters_enabled:
			var ignoredCharacters :Dictionary = info['ignored_characters']

			for character in text:

				if character in ignoredCharacters:
					continue

				calculated_delay += per_character_delay

		# Otherwise, we can just multiply the length of the text by the
		# delay.
		else:
			calculated_delay = text.length() * per_character_delay

	return calculated_delay


func _calculate_autoadvance_delay_from_str(text: String) -> float:
	# Preparing the text for auto-advance calculations.
	# We want to strip the BBCodes from the text as they contribute
	# negatively to the per-character and per-word calculation.
	print(text)
	text = DialogicUtil.strip_bbcode(text)

	var fixed_delay :float = Dialogic.Text.get_autoadvance_info()['fixed_delay']
	var delay_modifier :float = Dialogic.Settings.get_setting('autoadvance_delay_modifier', 1)

	var word_delay := _calculate_per_word_delay(text)
	var character_delay := _calculate_per_character_delay(text)

	# The delay calculation steps.
	var total_delay = word_delay + character_delay
	total_delay += Dialogic.current_state_info.get('text_time_taken', 0.0)
	total_delay *= delay_modifier
	total_delay += fixed_delay

	total_delay = max(0, total_delay)

	return total_delay


## Considers the settings for auto-advance and delays the
## auto-advance action accordingly.
##
## This method checks if a temporary auto-advance has been enabled.
## If `true`, the temporary delay will be used.
##
## Otherwise, the following steps will be taken:
## - If set, every word will add a delay.
## - If set, every character will add a delay, unless the character has been
## selected to be ignored by the user.
## - The time taken to type the text will be added.
## - The delay modifier will multiply the previously calculated delay.
## - The fixed delay will be added.
##
## If a voice is still playing and the voice's time left is greater than
## the delay, the voice's time left will be used a delay.
func start_autoadvance() -> void:
	if Dialogic.Text.should_autoadvance():
		var total_delay := 0.0
		var info: Dictionary = Dialogic.Text.get_autoadvance_info()

		if info['waiting_for_next_event'] == true and info['temp_wait_time'] > 0:
			total_delay = info['temp_wait_time']

		else:
			total_delay = _calculate_autoadvance_delay_from_str(Dialogic.current_state_info['text'])

		var voice_time_left: float = _voice_play_time_left()

		# If the voice clip duration is longer than the current delay,
		# we want to wait for the voice clip to finish instead.
		if voice_time_left > total_delay:
			total_delay = voice_time_left

		autoadvance_timer.start(total_delay)



func _on_autoadvance_timer_timeout() -> void:
	autoadvance.emit()
	autoadvance_timer.stop()

## Switches the auto-advance mode on or off based on [param is_enabled].
func _on_autoadvance_enabled_change(is_enabled: bool) -> void:
	# If auto-advance is enabled and we are not auto-advancing yet,
	# we will initiate the auto-advance mode.
	if (is_enabled and !is_autoadvancing()
	and Dialogic.current_state_info['text_time_taken'] > 0.0):
		Dialogic.Text.input_handler.start_autoadvance()

	# If auto-advance is disabled and we are auto-advancing,
	# we want to cancel the auto-advance mode.
	elif !is_enabled and is_autoadvancing():
		stop()

func is_autoadvancing() -> bool:
	return !autoadvance_timer.is_stopped()


func get_autoadvance_time_left() -> float:
	return autoadvance_timer.time_left


func get_autoadvance_time() -> float:
	return autoadvance_timer.wait_time


func pause() -> void:
	autoadvance_timer.paused = true
	input_block_timer.paused = true


func stop() -> void:
	autoadvance_timer.stop()
	input_block_timer.stop()

func resume() -> void:
	autoadvance_timer.paused = false
	input_block_timer.paused = false
