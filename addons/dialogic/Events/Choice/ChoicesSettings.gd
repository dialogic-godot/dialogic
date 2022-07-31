@tool
extends HBoxContainer

func refresh():
	%Autofocus.button_pressed = DialogicUtil.get_project_setting('dialogic/choices/autofocus_first', true)
	%Delay.value = DialogicUtil.get_project_setting('dialogic/choices/delay', 0.2)
	%FalseBehaviour.select(DialogicUtil.get_project_setting('dialogic/choices/def_false_bahviour', 0))
	%HotkeyType.select(DialogicUtil.get_project_setting('dialogic/choices/hotkey_behaviour', 0))


func _on_Autofocus_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/choices/autofocus_first', button_pressed)


func _on_FalseBehaviour_item_selected(index):
	ProjectSettings.set_setting('dialogic/choices/def_false_bahviour', index)


func _on_HotkeyType_item_selected(index):
	ProjectSettings.set_setting('dialogic/choices/hotkey_behaviour', index)


func _on_Delay_value_changed(value):
	ProjectSettings.set_setting('dialogic/choices/delay', value)
