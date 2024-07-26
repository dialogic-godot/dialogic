extends DialogicSubsystem

## Subsystem that allows entering and leaving an animation state.

signal finished
signal animation_interrupted

var prev_state: DialogicGameHandler.States = DialogicGameHandler.States.IDLE

var _is_animating := false

#region MAIN METHODS
####################################################################################################

func clear_game_state(_clear_flag := DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	stop_animation()


func is_animating() -> bool:
	return _is_animating


func start_animating() -> void:
	prev_state = dialogic.current_state
	dialogic.current_state = dialogic.States.ANIMATING
	_is_animating = true


func animation_finished(_arg := "") -> void:
	# It can happen that the animation state has already been stopped
	if not is_animating():
		return
	_is_animating = false
	dialogic.current_state = prev_state as DialogicGameHandler.States
	finished.emit()


func stop_animation() -> void:
	animation_finished()
	animation_interrupted.emit()

#endregion
