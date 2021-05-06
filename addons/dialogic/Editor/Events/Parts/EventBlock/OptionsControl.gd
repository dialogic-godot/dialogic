tool
extends MenuButton

signal action(action_name)

func _ready():
	var popup = get_popup()
	popup.connect("index_pressed", self, "_on_OptionSelected")


func _on_OptionSelected(index):
	if index == 0:
		emit_signal("action", "up")
	elif index == 1:
		emit_signal("action", "down")
	elif index == 3:
		emit_signal("action","remove")
