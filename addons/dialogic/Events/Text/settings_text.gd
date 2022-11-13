@tool
extends HBoxContainer

func refresh():
	%Info.add_theme_color_override('default_color', get_theme_color("accent_color", "Editor"))
	
	%DefaultSpeed.value = DialogicUtil.get_project_setting('dialogic/text/speed', 0.01)
	%Skippable.button_pressed = DialogicUtil.get_project_setting('dialogic/text/skippable', true)
	%Autocontinue.button_pressed = DialogicUtil.get_project_setting('dialogic/text/autocontinue', false)
	%AutocontinueDelay.value = DialogicUtil.get_project_setting('dialogic/text/autocontinue_delay', 1)
	%AutocolorNames.button_pressed = DialogicUtil.get_project_setting('dialogic/text/autocolor_names', false)
	%InputAction.resource_icon = get_theme_icon("Mouse", "EditorIcons")
	%InputAction.set_value(DialogicUtil.get_project_setting('dialogic/text/input_action', 'dialogic_default_action'))
	%InputAction.get_suggestions_func = suggest_actions


func _on_AutocontinueDelay_value_changed(value):
	ProjectSettings.set_setting('dialogic/text/autocontinue_delay', value)
	ProjectSettings.save()


func _on_Autocontinue_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/text/autocontinue', button_pressed)
	ProjectSettings.save()


func _on_Skippable_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/text/skippable', button_pressed)
	ProjectSettings.save()


func _on_DefaultSpeed_value_changed(value):
	ProjectSettings.set_setting('dialogic/text/speed', value)
	ProjectSettings.save()


func _on_InputAction_value_changed(property_name, value):
	ProjectSettings.set_setting('dialogic/text/input_action', value)
	ProjectSettings.save()

func suggest_actions(search):
	var suggs = {}
	for prop in ProjectSettings.get_property_list():
		if prop.name.begins_with('input/'):
			suggs[prop.name.trim_prefix('input/')] = {'value':prop.name.trim_prefix('input/')}
	return suggs


func _on_AutocolorNames_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/text/autocolor_names', button_pressed)
	ProjectSettings.save()
