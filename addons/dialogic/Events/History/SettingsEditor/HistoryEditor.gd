@tool
extends HBoxContainer

func refresh():
	%HistoryToggle.button_pressed = DialogicUtil.get_project_setting('dialogic/history/history_system', true)
	%FullHistory.button_pressed = DialogicUtil.get_project_setting('dialogic/history/full_history', true)
	%HistoryLength.value = DialogicUtil.get_project_setting('dialogic/history/full_history_length', 50)
	%TextHistory.button_pressed = DialogicUtil.get_project_setting('dialogic/history/text_history', true)
	%FullText.button_pressed = DialogicUtil.get_project_setting('dialogic/history/full_history_option_save_text', false)

func _on_history_toggle_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/history/history_system', button_pressed)
	ProjectSettings.save()


func _on_full_history_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/history/full_history', button_pressed)
	ProjectSettings.save()


func _on_history_length_value_changed(value):
	ProjectSettings.set_setting('dialogic/history/full_history_length', value)
	ProjectSettings.save()



func _on_text_history_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/history/text_history', button_pressed)
	ProjectSettings.save()


func _on_full_text_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/history/full_history_option_save_text', button_pressed)
	ProjectSettings.save()
	
