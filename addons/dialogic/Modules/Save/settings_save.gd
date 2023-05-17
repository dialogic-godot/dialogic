@tool
extends HBoxContainer

func refresh():
	%Autosave.button_pressed = ProjectSettings.get_setting('dialogic/save/autosave', false)
	%AutosaveMode.select(ProjectSettings.get_setting('dialogic/save/autosave_mode', 0))
	%DefaultSaveSlotName.text = ProjectSettings.get_setting('dialogic/save/default_slot', 'Default')
	%AutosaveDelay.value = ProjectSettings.get_setting('dialogic/save/autosave_delay', 60)
	%AutosaveDelayContainer.visible = %AutosaveMode.selected == 1

func _on_Autosave_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/save/autosave', button_pressed)
	ProjectSettings.save()
	
func _on_AutosaveMode_item_selected(index):
	ProjectSettings.set_setting('dialogic/save/autosave_mode', index)
	ProjectSettings.save()
	%AutosaveDelayContainer.visible = %AutosaveMode.selected == 1

func _on_AutosaveDelay_value_changed(value):
	ProjectSettings.set_setting('dialogic/save/autosave_delay', value)
	ProjectSettings.save()

func _on_DefaultSaveSlotName_text_changed(new_text):
	ProjectSettings.set_setting('dialogic/save/default_slot', new_text)
	ProjectSettings.save()
