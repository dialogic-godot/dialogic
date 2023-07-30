@tool
extends Node

signal dialogic_action()

var autoadvance_timer := Timer.new()
var input_block_timer := Timer.new()
var skip_delay :float = ProjectSettings.get_setting('dialogic/text/skippable_delay', 0.1)

################################################################################
## 						INPUT
################################################################################
func _input(event:InputEvent) -> void:
	if Input.is_action_just_pressed(ProjectSettings.get_setting('dialogic/text/input_action', 'dialogic_default_action')):
		if Dialogic.paused:
			return
		
		if is_input_blocked():
			return
		
		if Dialogic.current_state == Dialogic.States.IDLE and Dialogic.Text.can_manual_advance():
			Dialogic.handle_next_event()
			autoadvance_timer.stop()
			block_input(skip_delay)
		
		elif Dialogic.current_state == Dialogic.States.SHOWING_TEXT and Dialogic.Text.can_skip():
			Dialogic.Text.skip_text_animation()
			block_input(skip_delay)
		
		dialogic_action.emit()


func is_input_blocked() -> bool:
	return input_block_timer.time_left > 0.0


func block_input(time:=0.1) -> void:
	if time > 0:
		input_block_timer.stop()
		input_block_timer.wait_time = time
		input_block_timer.start()


####################################################################################################
##								AUTO-ADVANCING
####################################################################################################
func _ready() -> void:
	Dialogic.Text.text_finished.connect(_on_text_finished)
	add_child(autoadvance_timer)
	autoadvance_timer.one_shot = true
	autoadvance_timer.timeout.connect(_on_autoadvance_timer_timeout)
	
	add_child(input_block_timer)
	input_block_timer.one_shot = true


func _on_text_finished(info:Dictionary) -> void:
	if Dialogic.Text.should_autoadvance():
		autoadvance_timer.start(Dialogic.Text.get_autoadvance_time())


func _on_autoadvance_timer_timeout() -> void:
	Dialogic.handle_next_event()


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
