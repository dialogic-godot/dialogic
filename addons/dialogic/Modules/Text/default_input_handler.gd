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


func start_autoadvance() -> void:
	autoadvance_timer.start(Dialogic.Text.get_autoadvance_time())


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
