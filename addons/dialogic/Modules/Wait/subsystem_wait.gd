extends DialogicSubsystem

## Subsystem that manages wait events.

var _timer: Timer


#region STATE
####################################################################################################

func clear_game_state(clear_flag:=Dialogic.ClearFlags.FULL_CLEAR) -> void:
	if is_instance_valid(_timer):
		_timer.queue_free()


func pause() -> void:
	if is_instance_valid(_timer):
		_timer.paused = true


func resume() -> void:
	if is_instance_valid(_timer):
		_timer.paused = false

#endregion


#region MAIN METHODS
####################################################################################################

func update_wait(time: float, hide_text: bool, skippable: bool, callback: Callable) -> void:
	var final_wait_time := time

	if dialogic.Inputs.auto_skip.enabled:
		var time_per_event: float = dialogic.Inputs.auto_skip.time_per_event
		final_wait_time = min(time, time_per_event)

	dialogic.current_state = dialogic.States.WAITING

	if hide_text and dialogic.has_subsystem("Text"):
		dialogic.Text.update_dialog_text('', true)
		dialogic.Text.hide_textbox()

	_timer = Timer.new()
	_timer.one_shot = true
	if DialogicUtil.is_physics_timer():
		_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(_timer)
	_timer.start(final_wait_time)
	_timer.timeout.connect(callback.bind(_timer))

	if skippable:
		dialogic.Inputs.dialogic_action.connect(callback.bind(_timer))

#endregion
