extends Range

var enabled : bool = true

func _process(_delta : float) -> void:
	if !enabled:
		hide()
		return
	if DialogicUtil.autoload().Input.auto_advance.get_progress() < 0:
		hide()
	else:
		show()
		value = DialogicUtil.autoload().Input.auto_advance.get_progress()
