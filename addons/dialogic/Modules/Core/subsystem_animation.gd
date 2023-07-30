extends DialogicSubsystem

## Subsystem that allows entering and leaving an animation state.

signal finished

var prev_state : int = 0

####################################################################################################
##					MAIN METHODS
####################################################################################################

func is_animating() -> bool:
	return dialogic.current_state == dialogic.States.ANIMATING

func start_animating() -> void:
	prev_state = dialogic.current_state
	dialogic.current_state = dialogic.States.ANIMATING

func animation_finished(arg:String= "") -> void:
	dialogic.current_state = prev_state
	finished.emit()
	
