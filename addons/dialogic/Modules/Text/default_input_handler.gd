@tool
extends Node

var autoadvance_timer := Timer.new()
var skip_delay_timer := Timer.new()

signal dialogic_action()

################################################################################
## 						INPUT
################################################################################
func _input(event:InputEvent) -> void:
	if Input.is_action_just_pressed(ProjectSettings.get_setting('dialogic/text/input_action', 'dialogic_default_action')):
		if Dialogic.paused: return
		
		if skip_delay_timer.wait_time > 0.0:
			if skip_delay_timer.time_left > 0.0:
				return
			skip_delay_timer.start()
		
		if Dialogic.current_state == Dialogic.States.IDLE and Dialogic.Text.can_manual_advance():
			Dialogic.handle_next_event()
			autoadvance_timer.stop()
		
		elif Dialogic.current_state == Dialogic.States.SHOWING_TEXT and Dialogic.Text.can_skip():
			Dialogic.Text.skip_text_animation()
		
		dialogic_action.emit()


####################################################################################################
##								AUTO-ADVANCING
####################################################################################################
func _ready() -> void:
	Dialogic.Text.text_finished.connect(_on_text_finished)
	add_child(autoadvance_timer)
	autoadvance_timer.one_shot = true
	autoadvance_timer.timeout.connect(_on_autoadvance_timer_timeout)
	add_child(skip_delay_timer)
	skip_delay_timer.one_shot = true
	skip_delay_timer.wait_time = ProjectSettings.get_setting('dialogic/text/skippable_delay', 0.1)


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
	skip_delay_timer.paused = true

func resume() -> void:
	autoadvance_timer.paused = false
	skip_delay_timer.paused = false
