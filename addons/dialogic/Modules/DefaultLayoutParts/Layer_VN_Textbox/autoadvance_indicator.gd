extends Range

var enabled : bool = true

func _process(_delta : float) -> void:
	if !enabled:
		hide()
		return
	var auto_advance : DialogicAutoAdvance = DialogicUtil.autoload().get(&'Input').get(&'auto_advance')
	if auto_advance.get_progress() < 0:
		hide()
	else:
		show()
		value = auto_advance.get_progress()
