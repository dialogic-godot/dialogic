@tool
extends DialogicSettingsPage

var autopause_sets := {}

func _get_priority() -> int:
	return 98


func _get_title() -> String:
	return "Text"


func _get_info_section():
	return $InformationSection


func _ready():
	%ResetDelaysButton.icon = get_theme_icon("Reload", "EditorIcons")


func _refresh():
	%DefaultSpeed.value = ProjectSettings.get_setting('dialogic/text/letter_speed', 0.01)
	%Skippable.button_pressed = ProjectSettings.get_setting('dialogic/text/skippable', true)
	%SkippableDelay.value = ProjectSettings.get_setting('dialogic/text/skippable_delay', 0.1)

	%AutoAdvance.button_pressed = ProjectSettings.get_setting('dialogic/text/autoadvance_enabled', false)
	%FixedDelay.value = ProjectSettings.get_setting('dialogic/text/autoadvance_fixed_delay', 1)
	%PerCharacterDelay.value = ProjectSettings.get_setting('dialogic/text/autoadvance_per_character_delay', 0.01)
	%PerWordDelay.value = ProjectSettings.get_setting('dialogic/text/autoadvance_per_word_delay', 0.02)

	%IgnoredCharactersEnabled.button_pressed = ProjectSettings.get_setting('dialogic/text/autoadvance_ignored_characters_enabled', true)
	%IgnoredCharacters.text = str(ProjectSettings.get_setting('dialogic/text/autoadvance_ignored_characters', {}).keys())

	%AutocolorNames.button_pressed = ProjectSettings.get_setting('dialogic/text/autocolor_names', false)
	%TextboxHidden.button_pressed = ProjectSettings.get_setting('dialogic/text/hide_empty_textbox', true)
	%InputAction.resource_icon = get_theme_icon("Mouse", "EditorIcons")
	%InputAction.set_value(ProjectSettings.get_setting('dialogic/text/input_action', 'dialogic_default_action'))
	%InputAction.get_suggestions_func = suggest_actions

	%AutoPausesAbsolute.button_pressed = ProjectSettings.get_setting('dialogic/text/absolute_autopauses', false)
	%NewEvents.button_pressed = ProjectSettings.get_setting('dialogic/text/split_at_new_lines', false)
	%NewEventOption.select(ProjectSettings.get_setting('dialogic/text/split_at_new_lines_as', 0))
	load_autopauses(ProjectSettings.get_setting('dialogic/text/autopauses', {}))


func _about_to_close():
	save_autopauses()


func _on_FixedDelay_value_changed(value):
	ProjectSettings.set_setting('dialogic/text/autoadvance_fixed_delay', value)
	ProjectSettings.save()


func _on_PerWordDelay_value_changed(value):
	ProjectSettings.set_setting('dialogic/text/autoadvance_per_word_delay', value)
	ProjectSettings.save()


func _on_PerCharacterDelay_value_changed(value):
	ProjectSettings.set_setting('dialogic/text/autoadvance_per_character_delay', value)
	ProjectSettings.save()


func _on_Autoadvance_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/text/autoadvance_enabled', button_pressed)
	ProjectSettings.save()


func _on_IgnoredCharactersEnabled_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/text/autoadvance_ignored_characters_enabled', button_pressed)
	ProjectSettings.save()


func _on_IgnoredCharacters_text_changed(text_input):
	ProjectSettings.set_setting('dialogic/text/autoadvance_ignored_characters', DialogicUtil.str_to_hash_set(text_input))
	ProjectSettings.save()


func _on_ResetDelays_button_up() -> void:
	var default_is_auto_advanced_on := true
	DialogicUtil.set_editor_setting('autoadvance', default_is_auto_advanced_on)
	%AutoAdvance.button_pressed = default_is_auto_advanced_on

	var fixed_delay := 1
	DialogicUtil.set_editor_setting('autoadvance_fixed_delay', fixed_delay)
	%FixedDelay.value = fixed_delay

	var default_delay_per_character := 0.1
	DialogicUtil.set_editor_setting('autoadvance_delay_per_character', default_delay_per_character)
	%PerCharacterDelay.value = default_delay_per_character

	var default_delay_per_word := 0
	DialogicUtil.set_editor_setting('autoadvance_delay_per_word', default_delay_per_word)
	%PerWordDelay.value = default_delay_per_word

	var default_ignored_characters := '/\\,.( ); ?!-+"\''
	var default_ignored_characters_dictionary := DialogicUtil.str_to_hash_set(default_ignored_characters)
	DialogicUtil.set_editor_setting('autoadvance_ignored_characters', default_ignored_characters_dictionary)
	%IgnoredCharacters.text = default_ignored_characters

	var is_ignore_characters_enabled := true
	DialogicUtil.set_editor_setting('autoadvance_ignored_characters_enabled', is_ignore_characters_enabled)
	%IgnoredCharactersEnabled.button_pressed = is_ignore_characters_enabled


func _on_Skippable_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/text/skippable', button_pressed)
	ProjectSettings.save()


func _on_skippable_delay_value_changed(value: float) -> void:
	ProjectSettings.set_setting('dialogic/text/skippable_delay', value)
	ProjectSettings.save()


func _on_DefaultSpeed_value_changed(value):
	ProjectSettings.set_setting('dialogic/text/letter_speed', value)
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


func _on_AutocolorNames_toggled(button_pressed:bool) -> void:
	ProjectSettings.set_setting('dialogic/text/autocolor_names', button_pressed)
	ProjectSettings.save()


func _on_textbox_hidden_toggled(button_pressed:bool) -> void:
	ProjectSettings.set_setting('dialogic/text/hide_empty_textbox', button_pressed)
	ProjectSettings.save()


func load_autopauses(dictionary:Dictionary) -> void:
	for i in %AutoPauseSets.get_children():
		i.queue_free()


	for i in dictionary.keys():
		add_autopause_set(i, dictionary[i])



func save_autopauses() -> void:
	var dictionary := {}
	for i in autopause_sets:
		if is_instance_valid(autopause_sets[i].time):
			dictionary[autopause_sets[i].text.text] = autopause_sets[i].time.value
	ProjectSettings.set_setting('dialogic/text/autopauses', dictionary)
	ProjectSettings.save()


func _on_add_autopauses_set_pressed():
	add_autopause_set('', 0.1)


func add_autopause_set(text:String, time:float) -> void:
	var info := {}
	var line_edit := LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.placeholder_text = 'e.g. "?!.,;:"'
	line_edit.text = text
	info['text'] = line_edit
	%AutoPauseSets.add_child(line_edit)
	var spin_box := SpinBox.new()
	spin_box.min_value = 0.1
	spin_box.step = 0.01
	spin_box.value = time
	info['time'] = spin_box
	%AutoPauseSets.add_child(spin_box)

	var remove_btn := Button.new()
	remove_btn.icon = get_theme_icon('Remove', 'EditorIcons')
	remove_btn.pressed.connect(_on_remove_autopauses_set_pressed.bind(len(autopause_sets)))
	info['delete'] = remove_btn
	%AutoPauseSets.add_child(remove_btn)
	autopause_sets[len(autopause_sets)] = info


func _on_remove_autopauses_set_pressed(index:int) -> void:
	for key in autopause_sets[index]:
		autopause_sets[index][key].queue_free()
	autopause_sets.erase(index)


func _on_auto_pauses_absolute_toggled(button_pressed:bool) -> void:
	ProjectSettings.set_setting('dialogic/text/absolute_autopauses', button_pressed)
	ProjectSettings.save()


func _on_new_events_toggled(button_pressed:bool) -> void:
	ProjectSettings.set_setting('dialogic/text/split_at_new_lines', button_pressed)
	ProjectSettings.save()


func _on_new_event_option_item_selected(index:int) -> void:
	ProjectSettings.set_setting('dialogic/text/split_at_new_lines_as', index)
	ProjectSettings.save()
