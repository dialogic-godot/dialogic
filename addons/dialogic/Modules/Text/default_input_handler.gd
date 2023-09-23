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
func _input(event:InputEvent) -> void:
	if event.is_action_pressed(ProjectSettings.get_setting('dialogic/text/input_action', 'dialogic_default_action')):

		if Dialogic.paused or is_input_blocked():
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

	add_child(input_block_timer)
	input_block_timer.one_shot = true

## Checks how many words can be found by separating the text by whitespace.
## The current whitespaces supported is the normal ` `.
## In the future, this could be extended.
func _calculate_per_word_delay(text: String) -> float:
	var delay_per_word = Dialogic.Text.get_autoadvance_per_word_delay()

	var word_count = text.split(' ').size()
	var calculated_delay = word_count * delay_per_word

	return calculated_delay

## If a voice clip is still playing, returns the length of the voice clip in
## seconds.
##
## Auto-Advancing and Voice Clips:
## If the voice clip is still playing after the typewriter has finished,
## we must ensure that we do not auto-advance until the voice clip has finished.
## If the voice clip is not playing anymore, we can auto-advance as normal.
func _calculate_voice_delay() -> float:
	var voice_length = 0

	if Dialogic.Voice.voice_player.is_playing():
		voice_length = Dialogic.Voice.voice_player.stream.get_length()

	return voice_length

## Checks how many characters can be found by iterating each letter.
func _calculate_per_character_delay(text: String) -> float:
	var delay_per_character = Dialogic.Text.get_autoadvance_per_character_delay()
	var calculated_delay = 0

	if delay_per_character > 0:
		var is_ignored_characters_enabled = Dialogic.Text.get_autoadvance_ignored_characters_enabled()

		# If we have characters to ignore, we will iterate each letter.
		if is_ignored_characters_enabled:
			var ignoredCharacters = Dialogic.Text.get_autoadvance_ignored_characters()

			for character in text:

				if character in ignoredCharacters:
					continue

				calculated_delay += delay_per_character

		# Otherwise, we can just multiply the length of the text by the
		# delay.
		else:
			calculated_delay = text.length() * delay_per_character

	return calculated_delay

## Considers the settings for auto-advance and delays the
## auto-advance action accordingly.
##
## This method uses the displayed text and strips BBCode tags.
## If enabled, the following procedures are applied:
## - Every word will add a delay.
## - Every character will add a delay, unless the character has been
## selected to be ignored by the user.
## - The time taken to type the text will be added.
## - The delay modifier will be applied, this may resemble the player's reading
##  proficency. Setting it via the game settings is recommended.
## - The fixed delay will be added.
## - If the voice player is still playing, the voice clip duration will be
##  set as the delax duration if the voice exceeds the total auto-advance delay.
func start_autoadvance() -> void:
	if Dialogic.Text.should_autoadvance():
		# Preparing the text for auto-advance calculations.
		# We want to strip the BBCodes from the text as they contribute
		# negatively to the per-character and per-word calculation.
		var current_text = Dialogic.current_state_info.get('text', '')
		current_text = DialogicUtil.strip_bbcode(current_text)

		var fixed_delay = Dialogic.Text.get_autoadvance_fixed_delay()
		var delay_modifier = Dialogic.Text.get_autoadvance_delay_modifier()

		var word_delay = _calculate_per_word_delay(current_text)
		var character_delay = _calculate_per_character_delay(current_text)
		var voice_delay = _calculate_voice_delay()

		# The delay calculation steps.
		var total_delay = word_delay + character_delay
		total_delay += Dialogic.current_state_info.get('text_time_taken', 0.0)
		total_delay *= delay_modifier
		total_delay += fixed_delay

		# If the voice clip duration is longer than the current delay,
		# we want to wait for the voice clip to finish instead.
		if voice_delay > total_delay:
			total_delay = voice_delay

		total_delay = max(0, total_delay)
		autoadvance_timer.start(total_delay)

func _on_autoadvance_timer_timeout() -> void:
	autoadvance.emit()


func is_autoadvancing() -> bool:
	return !autoadvance_timer.is_stopped()


func get_autoadvance_time_left() -> float:
	return autoadvance_timer.time_left


func pause() -> void:
	autoadvance_timer.paused = true
	input_block_timer.paused = true

func resume() -> void:
	autoadvance_timer.paused = false
	input_block_timer.paused = false
