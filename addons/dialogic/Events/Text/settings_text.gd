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
	load_autopauses(DialogicUtil.get_project_setting('dialogic/text/autopauses', {}))


func _about_to_close():
	save_autopauses()

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

func suggest_actions(search:String) -> Dictionary:
	var suggs := {}
	for prop in ProjectSettings.get_property_list():
		if prop.name.begins_with('input/'):
			suggs[prop.name.trim_prefix('input/')] = {'value':prop.name.trim_prefix('input/')}
	return suggs


func _on_AutocolorNames_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/text/autocolor_names', button_pressed)
	ProjectSettings.save()


func load_autopauses(dictionary:Dictionary) -> void:
	for i in %AutoPauseSets.get_children():
		if i.get_index() != 0:
			i.queue_free()
	
	for i in dictionary.keys():
		add_autopause_set(i, dictionary[i])


func save_autopauses() -> void:
	var dictionary := {}
	for i in %AutoPauseSets.get_children():
		if i.get_index() != 0:
			if i.get_child(0).text:
				dictionary[i.get_child(0).text] = i.get_child(1).value
	ProjectSettings.set_setting('dialogic/text/autopauses', dictionary)
	ProjectSettings.save()


func _on_add_autopauses_set_pressed():
	add_autopause_set('', 0.1)


func add_autopause_set(text:String, time:float) -> void:
	var hbox := HBoxContainer.new()
	%AutoPauseSets.add_child(hbox)
	var line_edit := LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.placeholder_text = 'e.g. "?!.,;:"'
	line_edit.text = text
	hbox.add_child(line_edit)
	var spin_box := SpinBox.new()
	spin_box.min_value = 0.1
	spin_box.step = 0.01
	spin_box.value = time
	hbox.add_child(spin_box)
