@tool
extends DialogicSettingsPage

func _refresh() -> void:
	%Autofocus.button_pressed = ProjectSettings.get_setting('dialogic/choices/autofocus_first', true)
	%Delay.value = ProjectSettings.get_setting('dialogic/choices/delay', 0.2)
	%FalseBehaviour.select(ProjectSettings.get_setting('dialogic/choices/def_false_behaviour', 0))
	%HotkeyType.select(ProjectSettings.get_setting('dialogic/choices/hotkey_behaviour', 0))
	
	var reveal_delay :float = ProjectSettings.get_setting('dialogic/choices/reveal_delay', 0)
	var reveal_by_input :bool = ProjectSettings.get_setting('dialogic/choices/reveal_by_input', false)
	if not reveal_by_input and reveal_delay == 0:
		_on_appear_mode_item_selected(0)
	if not reveal_by_input and reveal_delay != 0:
		_on_appear_mode_item_selected(1)
	if reveal_by_input and reveal_delay == 0:
		_on_appear_mode_item_selected(2)
	if reveal_by_input and reveal_delay != 0:
		_on_appear_mode_item_selected(3)
	
	%RevealDelay.value = reveal_delay

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


func _on_reveal_delay_value_changed(value) -> void:
	ProjectSettings.set_setting('dialogic/choices/reveal_delay', value)
	ProjectSettings.save()


func _on_appear_mode_item_selected(index:int) -> void:
	%AppearMode.selected = index
	match index:
		0:
			ProjectSettings.set_setting('dialogic/choices/reveal_delay', 0)
			ProjectSettings.set_setting('dialogic/choices/reveal_by_input', false)
			%RevealDelay.hide()
		1:
			ProjectSettings.set_setting('dialogic/choices/reveal_delay', %RevealDelay.value)
			ProjectSettings.set_setting('dialogic/choices/reveal_by_input', false)
			%RevealDelay.show()
		2:
			ProjectSettings.set_setting('dialogic/choices/reveal_delay', 0)
			ProjectSettings.set_setting('dialogic/choices/reveal_by_input', true)
			%RevealDelay.hide()
		3:
			ProjectSettings.set_setting('dialogic/choices/reveal_delay', %RevealDelay.value)
			ProjectSettings.set_setting('dialogic/choices/reveal_by_input', true)
			%RevealDelay.show()
	ProjectSettings.save()
