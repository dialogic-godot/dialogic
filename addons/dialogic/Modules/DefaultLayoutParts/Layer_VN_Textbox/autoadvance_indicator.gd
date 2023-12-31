extends Range

var enabled : bool = true

func _process(_delta : float) -> void:
	if !enabled:
		hide()
		return
	var input_system : DialogicSubsystemInput = DialogicUtil.autoload().get(&'Input')
	if input_system.auto_advance.get_progress() < 0:
		hide()
	else:
		show()
		value = input_system.auto_advance.get_progress()
