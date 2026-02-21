extends Range

## Connects this range (e.g. ProgressBar) node to display when
## auto-advance is in progress and update its value.

@export var enabled: bool = true

func _process(_delta : float) -> void:
	if not enabled:
		hide()
		return

	if DialogicUtil.autoload().Inputs.auto_advance.get_progress() < 0:
		hide()

	else:
		show()
		value = DialogicUtil.autoload().Inputs.auto_advance.get_progress()
