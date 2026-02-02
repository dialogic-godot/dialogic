extends DialogicSubsystem

## Subsystem that manages wait events.

signal timeout

var _timer: Timer = Timer.new()


#region STATE
####################################################################################################

func clear_game_state(clear_flag:=Dialogic.ClearFlags.FULL_CLEAR) -> void:
	_timer.stop()


func pause() -> void:
	_timer.paused = true


func resume() -> void:
	_timer.paused = false

#endregion


#region MAIN METHODS
####################################################################################################

func _ready() -> void:
	_timer.one_shot = true
	if DialogicUtil.is_physics_timer():
		_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(_timer)
	_timer.timeout.connect(timeout.emit)


func update_wait(time: float, hide_text: bool, skippable: bool) -> void:
	var final_wait_time := time

	if dialogic.Inputs.auto_skip.enabled:
		var time_per_event: float = dialogic.Inputs.auto_skip.time_per_event
		final_wait_time = min(time, time_per_event)

	dialogic.current_state = dialogic.States.WAITING

	if hide_text and dialogic.has_subsystem("Text"):
		dialogic.Text.update_dialog_text('', true)
		dialogic.Text.hide_textbox()

	_timer.start(final_wait_time)

	if skippable:
		dialogic.Inputs.dialogic_action.connect(timeout.emit)

	await timeout
	_timer.stop()

	if skippable:
		dialogic.Inputs.dialogic_action.disconnect(timeout.emit)

#endregion
