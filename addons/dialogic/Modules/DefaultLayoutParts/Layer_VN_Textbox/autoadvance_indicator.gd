extends Range

var enabled : bool = true

func _process(_delta : float) -> void:
	if !enabled:
		hide()
		return
	var input_system : Node = DialogicUtil.autoload().get(&'Input')
	var auto_advance : DialogicAutoAdvance = input_system.get(&'auto_advance')
	if auto_advance.get_progress() < 0:
		hide()
	else:
		show()
		value = auto_advance.get_progress()
