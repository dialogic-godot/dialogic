tool
extends VBoxContainer


func _ready():
	var HistoryCheckbox = $"GridContainer/HistoryBox/SettingsCheckbox/CheckBox"
	HistoryCheckbox.connect('toggled', self, '_on_HistoryLogging_toggled')
	_on_HistoryLogging_toggled(HistoryCheckbox.pressed)


func _on_HistoryLogging_toggled(button_pressed):
	for n in $GridContainer.get_children():
		n.visible = button_pressed
	$GridContainer/HistoryBox.visible = true
