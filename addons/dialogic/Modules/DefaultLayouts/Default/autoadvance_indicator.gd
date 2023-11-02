extends Range

var enabled := true

func _process(delta):
	if !enabled:
		hide()
		return
	if Dialogic.Input.auto_advance.get_autoadvance_progress() < 0:
		hide()
	else:
		show()
		value = Dialogic.Input.auto_advance.get_autoadvance_progress()
