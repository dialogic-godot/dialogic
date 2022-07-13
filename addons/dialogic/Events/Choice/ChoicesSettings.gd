tool
extends HBoxContainer

func refresh():
	$'%Autofocus'.pressed = DialogicUtil.get_project_setting('dialogic/choices_autofocus_first', true)
	$'%Delay'.value = DialogicUtil.get_project_setting('dialogic/choices_delay', 0.2)
	$'%FalseBehaviour'.select(DialogicUtil.get_project_setting('dialogic/choices_def_false_bahviour', 0))
	$'%HotkeyType'.select(DialogicUtil.get_project_setting('dialogic/choices_hotkey_behaviour', 0))


func _on_Autofocus_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/choices_autofocus_first', button_pressed)


func _on_FalseBehaviour_item_selected(index):
	ProjectSettings.set_setting('dialogic/choices_def_false_bahviour', index)


func _on_HotkeyType_item_selected(index):
	ProjectSettings.set_setting('dialogic/choices_hotkey_behaviour', index)


func _on_Delay_value_changed(value):
	ProjectSettings.set_setting('dialogic/choices_delay', value)
