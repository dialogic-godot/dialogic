@tool
extends HBoxContainer

func refresh() -> void:
	%Autofocus.button_pressed = DialogicUtil.get_project_setting('dialogic/choices/autofocus_first', true)
	var delay_value:float = DialogicUtil.get_project_setting('dialogic/choices/delay', 0.2)
	%Delay.value = delay_value
	%FalseBehaviour.select(DialogicUtil.get_project_setting('dialogic/choices/def_false_behaviour', 0))
	%HotkeyType.select(DialogicUtil.get_project_setting('dialogic/choices/hotkey_behaviour', 0))


func _on_Autofocus_toggled(button_pressed: bool) -> void:
	ProjectSettings.set_setting('dialogic/choices/autofocus_first', button_pressed)
	ProjectSettings.save()


func _on_FalseBehaviour_item_selected(index) -> void:
	ProjectSettings.set_setting('dialogic/choices/def_false_behaviour', index)
	ProjectSettings.save()


func _on_HotkeyType_item_selected(index) -> void:
	ProjectSettings.set_setting('dialogic/choices/hotkey_behaviour', index)
	ProjectSettings.save()


func _on_Delay_value_changed(value) -> void:
	ProjectSettings.set_setting('dialogic/choices/delay', value)
	ProjectSettings.save()
