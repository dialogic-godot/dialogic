extends Range

var enabled := true

func _process(delta):
	if !enabled:
		hide()
		return
	if DialogicUtil.autoload().Input.auto_advance.get_progress() < 0:
		hide()
	else:
		show()
		value = DialogicUtil.autoload().Input.auto_advance.get_progress()
