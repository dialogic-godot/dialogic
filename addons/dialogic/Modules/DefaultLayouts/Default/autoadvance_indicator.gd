extends Range

func _process(delta):
	if Dialogic.Text.get_autoadvance_progress() < 0:
		hide()
	else:
		show()
		value = Dialogic.Text.get_autoadvance_progress()
