extends DialogicSubsystem

## Subsystem that manages wait events.

var _tween: Tween


#region STATE
####################################################################################################

func clear_game_state(clear_flag:=Dialogic.ClearFlags.FULL_CLEAR) -> void:
	if is_instance_valid(_tween):
		_tween.kill()


func pause() -> void:
	if is_instance_valid(_tween):
		_tween.pause()


func resume() -> void:
	if is_instance_valid(_tween):
		_tween.play()

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

	_tween = dialogic.get_tree().create_tween()
	if DialogicUtil.is_physics_timer():
		_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_callback(callback.bind(_tween)).set_delay(final_wait_time)

	if skippable:
		dialogic.Inputs.dialogic_action.connect(callback.bind(_tween))

#endregion
