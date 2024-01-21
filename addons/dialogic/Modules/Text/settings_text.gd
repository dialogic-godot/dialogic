@tool
extends DialogicSettingsPage

var autopause_sets := {}

func _get_priority() -> int:
	return 98


func _get_title() -> String:
	return "Text"


func _refresh() -> void:
	%DefaultSpeed.value = ProjectSettings.get_setting('dialogic/text/letter_speed', 0.01)
	%Skippable.button_pressed = ProjectSettings.get_setting('dialogic/text/initial_text_reveal_skippable', true)
	%SkippableDelay.value = ProjectSettings.get_setting('dialogic/text/skippable_delay', 0.1)

	%AutoAdvance.button_pressed = ProjectSettings.get_setting('dialogic/text/autoadvance_enabled', false)
	%FixedDelay.value = ProjectSettings.get_setting('dialogic/text/autoadvance_fixed_delay', 1)

	var per_character_delay: float = ProjectSettings.get_setting('dialogic/text/autoadvance_per_character_delay', 0.1)
	var per_word_delay: float = ProjectSettings.get_setting('dialogic/text/autoadvance_per_word_delay', 0)
	if per_character_delay == 0 and per_word_delay == 0:
		_on_additional_delay_mode_item_selected(0)
	elif per_word_delay == 0:
		_on_additional_delay_mode_item_selected(2, per_character_delay)
	else:
		_on_additional_delay_mode_item_selected(1, per_word_delay)

	%IgnoredCharactersEnabled.button_pressed = ProjectSettings.get_setting('dialogic/text/autoadvance_ignored_characters_enabled', true)

	var ignored_characters: String = ''
	var ignored_characters_dict: Dictionary = ProjectSettings.get_setting('dialogic/text/autoadvance_ignored_characters', {})

	for ignored_character in ignored_characters_dict.keys():
		ignored_characters += ignored_character

	%IgnoredCharacters.text = ignored_characters

	%AutoskipTimePerEvent.value = ProjectSettings.get_setting('dialogic/text/autoskip_time_per_event', 0.1)

	%AutocolorNames.button_pressed = ProjectSettings.get_setting('dialogic/text/autocolor_names', false)
	%InputAction.resource_icon = get_theme_icon("Mouse", "EditorIcons")
	%InputAction.set_value(ProjectSettings.get_setting('dialogic/text/input_action', 'dialogic_default_action'))
	%InputAction.get_suggestions_func = suggest_actions

	%AutoPausesAbsolute.button_pressed = ProjectSettings.get_setting('dialogic/text/absolute_autopauses', false)
	%NewEvents.button_pressed = ProjectSettings.get_setting('dialogic/text/split_at_new_lines', false)
	%NewEventOption.select(ProjectSettings.get_setting('dialogic/text/split_at_new_lines_as', 0))
	load_autopauses(ProjectSettings.get_setting('dialogic/text/autopauses', {}))


func _about_to_close():
	save_autopauses()


func _on_Autoadvance_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/text/autoadvance_enabled', button_pressed)
	ProjectSettings.save()


func _on_FixedDelay_value_changed(value):
	ProjectSettings.set_setting('dialogic/text/autoadvance_fixed_delay', value)
	ProjectSettings.save()


func _on_additional_delay_mode_item_selected(index:int, delay:float=-1) -> void:
	%AdditionalDelayMode.selected = index
	match index:
		0: # NONE
			%AdditionalDelay.hide()
			%AutoadvanceIgnoreCharacters.hide()
			ProjectSettings.set_setting('dialogic/text/autoadvance_per_word_delay', 0)
			ProjectSettings.set_setting('dialogic/text/autoadvance_per_character_delay', 0)
		1: # PER WORD
			%AdditionalDelay.show()
			%AutoadvanceIgnoreCharacters.hide()
			if delay != -1:
				%AdditionalDelay.value = delay
			else:
				ProjectSettings.set_setting('dialogic/text/autoadvance_per_word_delay', %AdditionalDelay.value)
				ProjectSettings.set_setting('dialogic/text/autoadvance_per_character_delay', 0)
		2: # PER CHARACTER
			%AdditionalDelay.show()
			%AutoadvanceIgnoreCharacters.show()
			if delay != -1:
				%AdditionalDelay.value = delay
			else:
				ProjectSettings.set_setting('dialogic/text/autoadvance_per_character_delay', %AdditionalDelay.value)
				ProjectSettings.set_setting('dialogic/text/autoadvance_per_word_delay', 0)
	ProjectSettings.save()


func _on_additional_delay_value_changed(value:float) -> void:
	match %AdditionalDelayMode.selected:
		0: # NONE
			ProjectSettings.set_setting('dialogic/text/autoadvance_per_character_delay', 0)
			ProjectSettings.set_setting('dialogic/text/autoadvance_per_word_delay', 0)
		1: # PER WORD
			ProjectSettings.set_setting('dialogic/text/autoadvance_per_word_delay', value)
		2: # PER CHARACTER
			ProjectSettings.set_setting('dialogic/text/autoadvance_per_character_delay', value)
	ProjectSettings.save()


func _on_IgnoredCharactersEnabled_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/text/autoadvance_ignored_characters_enabled', button_pressed)
	ProjectSettings.save()


func _on_IgnoredCharacters_text_changed(text_input):
	ProjectSettings.set_setting('dialogic/text/autoadvance_ignored_characters', DialogicUtil.str_to_hash_set(text_input))
	ProjectSettings.save()


func _on_Skippable_toggled(button_pressed):
	ProjectSettings.set_setting('dialogic/text/initial_text_reveal_skippable', button_pressed)
	ProjectSettings.save()


func _on_skippable_delay_value_changed(value: float) -> void:
	ProjectSettings.set_setting('dialogic/text/text_reveal_skip_delay', value)
	ProjectSettings.save()


func _on_DefaultSpeed_value_changed(value):
	ProjectSettings.set_setting('dialogic/text/letter_speed', value)
	ProjectSettings.save()

func _on_AutoskipTimePerEvent_value_changed(value: float) -> void:
	ProjectSettings.set_setting('dialogic/text/autoskip_time_per_event', value)
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

