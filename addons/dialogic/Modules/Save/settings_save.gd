@tool
extends DialogicSettingsPage

## Settings page that contains settings for the saving subsystem


func _get_priority() -> int:
	return 0


func _refresh():
	%Autosave.button_pressed = ProjectSettings.get_setting('dialogic/save/autosave', false)
	%AutosaveMode.select(ProjectSettings.get_setting('dialogic/save/autosave_mode', 0))
	%AutosaveDelay.value = ProjectSettings.get_setting('dialogic/save/autosave_delay', 60)

	%AutosaveModeLabel.visible = %Autosave.button_pressed
	%AutosaveModeContent.visible = %Autosave.button_pressed
	%AutosaveDelay.visible = %AutosaveMode.selected == 1

	%DefaultSaveSlotName.text = ProjectSettings.get_setting('dialogic/save/default_slot', 'Default')

	%EncryptionPassword.text = ProjectSettings.get_setting('dialogic/save/encryption_password', "")
	%EncryptionOnExportsSection.visible = !%EncryptionPassword.text.is_empty()
	%EncryptionOnExports.button_pressed = ProjectSettings.get_setting('dialogic/save/encryption_on_exports_only', true)

func _on_autosave_toggled(button_pressed:bool) -> void:
	ProjectSettings.set_setting('dialogic/save/autosave', button_pressed)
	ProjectSettings.save()
	%AutosaveModeLabel.visible = button_pressed
	%AutosaveModeContent.visible = button_pressed


func _on_autosave_mode_item_selected(index:int):
	ProjectSettings.set_setting('dialogic/save/autosave_mode', index)
	ProjectSettings.save()
	%AutosaveDelay.visible = %AutosaveMode.selected == 1


func _on_autosave_delay_value_changed(value:float):
	ProjectSettings.set_setting('dialogic/save/autosave_delay', value)
	ProjectSettings.save()


func _on_default_save_slot_name_text_changed(new_text:String):
	ProjectSettings.set_setting('dialogic/save/default_slot', new_text)
	ProjectSettings.save()


func _on_encryption_password_text_changed(new_text: String) -> void:
	ProjectSettings.set_setting('dialogic/save/encryption_password', new_text)
	ProjectSettings.save()
	%EncryptionOnExportsSection.visible = !new_text.is_empty()


func _on_encryption_on_exports_toggled(toggled_on:bool) -> void:
	ProjectSettings.set_setting('dialogic/save/encryption_on_exports_only', toggled_on)
	ProjectSettings.save()
