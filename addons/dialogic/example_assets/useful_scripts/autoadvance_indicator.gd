extends Range

## Connects this range (e.g. ProgressBar) node to display when
## auto-advance is in progress and update its value.

@export var enabled := true
@export var hide_when_not_in_progress := true
@export var hide_when_auto_advance_is_disabled := true

func _process(_delta : float) -> void:
	if not enabled:
		hide()
		return

	if hide_when_not_in_progress and DialogicUtil.autoload().Inputs.auto_advance.get_progress() < 0:
		hide()
	elif hide_when_auto_advance_is_disabled and not DialogicUtil.autoload().Inputs.auto_advanced.is_enabled():
		hide()
	else:
		show()
		value = DialogicUtil.autoload().Inputs.auto_advance.get_progress()
