@tool
extends DialogicSettingsPage

var autopause_sets := {}

const _SETTING_LETTER_SPEED := 'dialogic/text/letter_speed'

const _SETTING_INPUT_ACTION := 'dialogic/text/input_action'

const _SETTING_TEXT_REVEAL_SKIPPABLE 		:= 'dialogic/text/initial_text_reveal_skippable'
const _SETTING_TEXT_REVEAL_SKIPPABLE_DELAY 	:= 'dialogic/text/text_reveal_skip_delay'
const _SETTING_TEXT_ADVANCE_DELAY 			:= 'dialogic/text/advance_delay'

const _SETTING_AUTOCOLOR_NAMES 				:= 'dialogic/text/autocolor_names'
const _SETTING_SPLIT_AT_NEW_LINES 			:= 'dialogic/text/split_at_new_lines'
const _SETTING_SPLIT_AT_NEW_LINES_AS 		:= 'dialogic/text/split_at_new_lines_as'

const _SETTING_AUTOSKIP_TIME_PER_EVENT 		:= 'dialogic/text/autoskip_time_per_event'

const _SETTING_AUTOADVANCE_ENABLED 			:= 'dialogic/text/autoadvance_enabled'
const _SETTING_AUTOADVANCE_FIXED_DELAY 		:= 'dialogic/text/autoadvance_fixed_delay'
const _SETTING_AUTOADVANCE_WORD_DELAY 		:= 'dialogic/text/autoadvance_per_word_delay'
const _SETTING_AUTOADVANCE_CHARACTER_DELAY 	:= 'dialogic/text/autoadvance_per_character_delay'
const _SETTING_AUTOADVANCE_IGNORED_CHARACTERS_ENABLED 	:= 'dialogic/text/autoadvance_ignored_characters_enabled'
const _SETTING_AUTOADVANCE_IGNORED_CHARACTERS	:= 'dialogic/text/autoadvance_ignored_characters'

const _SETTING_ABSOLUTE_AUTOPAUSES 	:= 'dialogic/text/absolute_autopauses'
const _SETTING_AUTOPAUSES 	:= 'dialogic/text/autopauses'


func _get_priority() -> int:
	return 98


func _get_title() -> String:
	return "Text"


func _ready() -> void:
	%DefaultSpeed.value_changed.connect(_on_float_set.bind(_SETTING_LETTER_SPEED))

	%Skippable.toggled.connect(_on_bool_set.bind(_SETTING_TEXT_REVEAL_SKIPPABLE))
	%SkippableDelay.value_changed.connect(_on_float_set.bind(_SETTING_TEXT_REVEAL_SKIPPABLE_DELAY))
	%AdvanceDelay.value_changed.connect(_on_float_set.bind(_SETTING_TEXT_ADVANCE_DELAY))

	%AutocolorNames.toggled.connect(_on_bool_set.bind(_SETTING_AUTOCOLOR_NAMES))

	%NewEvents.toggled.connect(_on_bool_set.bind(_SETTING_SPLIT_AT_NEW_LINES))

	%AutoAdvance.toggled.connect(_on_bool_set.bind(_SETTING_AUTOADVANCE_ENABLED))
	%FixedDelay.value_changed.connect(_on_float_set.bind(_SETTING_AUTOADVANCE_FIXED_DELAY))
	%IgnoredCharactersEnabled.toggled.connect(_on_bool_set.bind(_SETTING_AUTOADVANCE_IGNORED_CHARACTERS_ENABLED))

	%AutoskipTimePerEvent.value_changed.connect(_on_float_set.bind(_SETTING_AUTOSKIP_TIME_PER_EVENT))

	%AutoPausesAbsolute.toggled.connect(_on_bool_set.bind(_SETTING_ABSOLUTE_AUTOPAUSES))


func _refresh() -> void:
	## BEHAVIOUR
	%DefaultSpeed.value = ProjectSettings.get_setting(_SETTING_LETTER_SPEED, 0.01)

	%InputAction.resource_icon = get_theme_icon(&"Mouse", &"EditorIcons")
	%InputAction.set_value(ProjectSettings.get_setting(_SETTING_INPUT_ACTION, &'dialogic_default_action'))
	%InputAction.get_suggestions_func = suggest_actions

	%Skippable.button_pressed = ProjectSettings.get_setting(_SETTING_TEXT_REVEAL_SKIPPABLE, true)
	%SkippableDelay.value = ProjectSettings.get_setting(_SETTING_TEXT_REVEAL_SKIPPABLE_DELAY, 0.1)
	%AdvanceDelay.value = ProjectSettings.get_setting(_SETTING_TEXT_ADVANCE_DELAY, 0.1)

	%AutocolorNames.button_pressed = ProjectSettings.get_setting(_SETTING_AUTOCOLOR_NAMES, false)

	%NewEvents.button_pressed = ProjectSettings.get_setting(_SETTING_SPLIT_AT_NEW_LINES, false)
	%NewEventOption.select(ProjectSettings.get_setting(_SETTING_SPLIT_AT_NEW_LINES_AS, 0))

	## AUTO-ADVANCE
	%AutoAdvance.button_pressed = ProjectSettings.get_setting(_SETTING_AUTOADVANCE_ENABLED, false)
	%FixedDelay.value = ProjectSettings.get_setting(_SETTING_AUTOADVANCE_FIXED_DELAY, 1)

	var per_character_delay: float = ProjectSettings.get_setting(_SETTING_AUTOADVANCE_CHARACTER_DELAY, 0.1)
	var per_word_delay: float = ProjectSettings.get_setting(_SETTING_AUTOADVANCE_WORD_DELAY, 0)
	if per_character_delay == 0 and per_word_delay == 0:
		_on_additional_delay_mode_item_selected(0)
	elif per_word_delay == 0:
		_on_additional_delay_mode_item_selected(2, per_character_delay)
	else:
		_on_additional_delay_mode_item_selected(1, per_word_delay)

	%IgnoredCharactersEnabled.button_pressed = ProjectSettings.get_setting(_SETTING_AUTOADVANCE_IGNORED_CHARACTERS_ENABLED, true)
	var ignored_characters: String = ''
	var ignored_characters_dict: Dictionary = ProjectSettings.get_setting(_SETTING_AUTOADVANCE_IGNORED_CHARACTERS, {})
	for ignored_character in ignored_characters_dict.keys():
		ignored_characters += ignored_character
	%IgnoredCharacters.text = ignored_characters

	## AUTO-SKIP
	%AutoskipTimePerEvent.value = ProjectSettings.get_setting(_SETTING_AUTOSKIP_TIME_PER_EVENT, 0.1)

	## AUTO-PAUSES
	%AutoPausesAbsolute.button_pressed = ProjectSettings.get_setting(_SETTING_ABSOLUTE_AUTOPAUSES, false)
	load_autopauses(ProjectSettings.get_setting(_SETTING_AUTOPAUSES, {}))


func _about_to_close() -> void:
	save_autopauses()


func _on_bool_set(button_pressed:bool, setting:String) -> void:
	ProjectSettings.set_setting(setting, button_pressed)
	ProjectSettings.save()


func _on_float_set(value:float, setting:String) -> void:
	ProjectSettings.set_setting(setting, value)
	ProjectSettings.save()


#region BEHAVIOUR
################################################################################

func _on_InputAction_value_changed(property_name:String, value:String) -> void:
	ProjectSettings.set_setting(_SETTING_INPUT_ACTION, value)
	ProjectSettings.save()

func suggest_actions(search:String) -> Dictionary:
	var suggs := {}
	for prop in ProjectSettings.get_property_list():
		if prop.name.begins_with('input/') and not prop.name.begins_with('input/ui_') :
			suggs[prop.name.trim_prefix('input/')] = {'value':prop.name.trim_prefix('input/')}
	return suggs


func _on_new_event_option_item_selected(index:int) -> void:
	ProjectSettings.set_setting(_SETTING_SPLIT_AT_NEW_LINES_AS, index)
	ProjectSettings.save()

#endregion

#region AUTO-ADVANCE
################################################################################

func _on_additional_delay_mode_item_selected(index:int, delay:float=-1) -> void:
	%AdditionalDelayMode.selected = index
	match index:
		0: # NONE
			%AdditionalDelay.hide()
			%AutoadvanceIgnoreCharacters.hide()
			ProjectSettings.set_setting(_SETTING_AUTOADVANCE_WORD_DELAY, 0)
			ProjectSettings.set_setting(_SETTING_AUTOADVANCE_CHARACTER_DELAY, 0)
		1: # PER WORD
			%AdditionalDelay.show()
			%AutoadvanceIgnoreCharacters.hide()
			if delay != -1:
				%AdditionalDelay.value = delay
			else:
				ProjectSettings.set_setting(_SETTING_AUTOADVANCE_WORD_DELAY, %AdditionalDelay.value)
				ProjectSettings.set_setting(_SETTING_AUTOADVANCE_CHARACTER_DELAY, 0)
		2: # PER CHARACTER
			%AdditionalDelay.show()
			%AutoadvanceIgnoreCharacters.show()
			if delay != -1:
				%AdditionalDelay.value = delay
			else:
				ProjectSettings.set_setting(_SETTING_AUTOADVANCE_CHARACTER_DELAY, %AdditionalDelay.value)
				ProjectSettings.set_setting(_SETTING_AUTOADVANCE_WORD_DELAY, 0)
	ProjectSettings.save()


func _on_additional_delay_value_changed(value:float) -> void:
	match %AdditionalDelayMode.selected:
		0: # NONE
			ProjectSettings.set_setting(_SETTING_AUTOADVANCE_CHARACTER_DELAY, 0)
			ProjectSettings.set_setting(_SETTING_AUTOADVANCE_WORD_DELAY, 0)
		1: # PER WORD
			ProjectSettings.set_setting(_SETTING_AUTOADVANCE_WORD_DELAY, value)
		2: # PER CHARACTER
			ProjectSettings.set_setting(_SETTING_AUTOADVANCE_CHARACTER_DELAY, value)
	ProjectSettings.save()


func _on_IgnoredCharacters_text_changed(text_input):
	ProjectSettings.set_setting(_SETTING_AUTOADVANCE_IGNORED_CHARACTERS, DialogicUtil.str_to_hash_set(text_input))
	ProjectSettings.save()

#endregion


## AUTO-PAUSES
################################################################################

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
	ProjectSettings.set_setting(_SETTING_AUTOPAUSES, dictionary)
	ProjectSettings.save()


func _on_add_autopauses_set_pressed() -> void:
	add_autopause_set('', 0.1)


func add_autopause_set(text: String, time: float) -> void:
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
	remove_btn.icon = get_theme_icon(&'Remove', &'EditorIcons')
	remove_btn.pressed.connect(_on_remove_autopauses_set_pressed.bind(len(autopause_sets)))
	info['delete'] = remove_btn
	%AutoPauseSets.add_child(remove_btn)
	autopause_sets[len(autopause_sets)] = info


func _on_remove_autopauses_set_pressed(index: int) -> void:
	for key in autopause_sets[index]:
		autopause_sets[index][key].queue_free()
	autopause_sets.erase(index)

