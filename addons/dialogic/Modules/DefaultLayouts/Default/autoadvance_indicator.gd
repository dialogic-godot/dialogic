extends Range

var enabled := true

func _process(delta):
	if !enabled:
		hide()
		return
	if Dialogic.Text.get_autoadvance_progress() < 0:
		hide()
	else:
		show()
		value = Dialogic.Text.get_autoadvance_progress()
