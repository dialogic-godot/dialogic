@tool
extends HBoxContainer

func refresh() -> void:
	%Autofocus.button_pressed = DialogicUtil.get_project_setting('dialogic/choices/autofocus_first', true)
	%Delay.value = DialogicUtil.get_project_setting('dialogic/choices/delay', 0.2)
	%FalseBehaviour.select(DialogicUtil.get_project_setting('dialogic/choices/def_false_behaviour', 0))
	%HotkeyType.select(DialogicUtil.get_project_setting('dialogic/choices/hotkey_behaviour', 0))


func _on_Autofocus_toggled(button_pressed: bool) -> void:
	ProjectSettings.set_setting('dialogic/choices/autofocus_first', button_pressed)


func _on_FalseBehaviour_item_selected(index) -> void:
	ProjectSettings.set_setting('dialogic/choices/def_false_behaviour', index)


func _on_HotkeyType_item_selected(index) -> void:
	ProjectSettings.set_setting('dialogic/choices/hotkey_behaviour', index)


func _on_Delay_value_changed(value) -> void:
	ProjectSettings.set_setting('dialogic/choices/delay', value)
