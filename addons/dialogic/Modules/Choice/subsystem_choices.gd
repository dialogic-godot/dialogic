extends DialogicSubsystem

## Subsystem that manages showing and activating of choices.

## Emitted when a choice button was pressed. Info includes the keys 'button_index', 'text', 'event_index'.
signal choice_selected(info:Dictionary)
## Emitted when a set of choices is reached and shown.
## Info includes the keys 'choices' (an array of dictionaries with infos on all the choices).
signal choices_shown(info:Dictionary)

## Contains information on the latest question.
var last_question_info := {}

## The delay between the text finishing revealing and the choices appearing
var reveal_delay: float = 0.0
## If true the player has to click to reveal choices when they are reached
var reveal_by_input: bool = false
## The delay between the choices becoming visible and being clickable. Can prevent accidental selection.
var block_delay: float = 0.2
## If true, the first (top-most) choice will be focused
var autofocus_first_choice: bool = true

enum FalseBehaviour {HIDE=0, DISABLE=1}
## The behaviour of choices with a false condition and else_action set to DEFAULT.
var default_false_behaviour := FalseBehaviour.HIDE

enum HotkeyBehaviour {NONE, NUMBERS}
## Will add some hotkeys to the choices if different then HotkeyBehaviour.NONE.
var hotkey_behaviour := HotkeyBehaviour.NONE


### INTERNALS

## Used to block choices from being clicked for a couple of seconds (if delay is set in settings).
var _choice_blocker := Timer.new()

#region STATE
####################################################################################################

func clear_game_state(clear_flag:=DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	hide_all_choices()


func _ready() -> void:
	_choice_blocker.one_shot = true
	DialogicUtil.update_timer_process_callback(_choice_blocker)
	add_child(_choice_blocker)

	reveal_delay = float(ProjectSettings.get_setting('dialogic/choices/reveal_delay', reveal_delay))
	reveal_by_input = ProjectSettings.get_setting('dialogic/choices/reveal_by_input', reveal_by_input)
	block_delay = ProjectSettings.get_setting('dialogic/choices/delay', block_delay)
	autofocus_first_choice = ProjectSettings.get_setting('dialogic/choices/autofocus_first', autofocus_first_choice)
	hotkey_behaviour = ProjectSettings.get_setting('dialogic/choices/hotkey_behaviour', hotkey_behaviour)
	default_false_behaviour = ProjectSettings.get_setting('dialogic/choices/def_false_behaviour', default_false_behaviour)

#endregion


#region MAIN METHODS
####################################################################################################

## Hides all choice buttons.
func hide_all_choices() -> void:
	for node in get_tree().get_nodes_in_group('dialogic_choice_button'):
		node.hide()
		if node.is_connected('button_up', _on_ChoiceButton_choice_selected):
			node.disconnect('button_up', _on_ChoiceButton_choice_selected)


## Lists all current choices and shows buttons.
func show_current_choices(instant:=true) -> void:
	hide_all_choices()
	_choice_blocker.stop()

	if !instant and (reveal_delay != 0 or reveal_by_input):
		if reveal_delay != 0:
			_choice_blocker.start(reveal_delay)
			_choice_blocker.timeout.connect(show_current_choices)
		if reveal_by_input:
			dialogic.Inputs.dialogic_action.connect(show_current_choices)
		return

	if _choice_blocker.timeout.is_connected(show_current_choices):
		_choice_blocker.timeout.disconnect(show_current_choices)
	if dialogic.Inputs.dialogic_action.is_connected(show_current_choices):
		dialogic.Inputs.dialogic_action.disconnect(show_current_choices)


	var button_idx := 1
	last_question_info = {'choices':[]}
	for choice_index in get_current_choice_indexes():
		var choice_event: DialogicEvent = dialogic.current_timeline_events[choice_index]
		# check if condition is false
		if not choice_event.condition.is_empty() and not dialogic.Expressions.execute_condition(choice_event.condition):
			if choice_event.else_action == DialogicChoiceEvent.ElseActions.DEFAULT:
				choice_event.else_action = default_false_behaviour

			# check what to do in this case
			if choice_event.else_action == DialogicChoiceEvent.ElseActions.DISABLE:
				if !choice_event.disabled_text.is_empty():
					show_choice(button_idx, choice_event.get_property_translated('disabled_text'), false, choice_index)
					last_question_info['choices'].append(choice_event.get_property_translated('disabled_text')+'#disabled')
				else:
					show_choice(button_idx, choice_event.get_property_translated('text'), false, choice_index)
					last_question_info['choices'].append(choice_event.get_property_translated('text')+'#disabled')
				button_idx += 1
		# else just show it
		else:
			show_choice(button_idx, choice_event.get_property_translated('text'), true, choice_index)
			last_question_info['choices'].append(choice_event.get_property_translated('text'))
			button_idx += 1
	choices_shown.emit(last_question_info)
	_choice_blocker.start(block_delay)


## Adds a button with the given text that leads to the given event.
func show_choice(button_index:int, text:String, enabled:bool, event_index:int) -> void:
	var idx := 1
	var shown_at_all := false
	for node: DialogicNode_ChoiceButton in get_tree().get_nodes_in_group('dialogic_choice_button'):
		if !node.get_parent().is_visible_in_tree():
			continue
		if (node.choice_index == button_index) or (idx == button_index and node.choice_index == -1):
			node.show()


			if dialogic.has_subsystem('Text'):
				text = dialogic.Text.parse_text(text, true, true, false, true, false, false)

			node._set_text_changed(text)

			if idx == 1 and autofocus_first_choice:
				node.grab_focus()

			## Add 1 to 9 as shortcuts if it's enabled
			match hotkey_behaviour:
				HotkeyBehaviour.NUMBERS:
					if idx > 0 or idx < 10:
						var shortcut: Shortcut
						if node.shortcut != null:
							shortcut = node.shortcut
						else:
							shortcut = Shortcut.new()

						var shortcut_events: Array[InputEventKey] = []
						var input_key := InputEventKey.new()
						input_key.keycode = OS.find_keycode_from_string(str(idx))
						shortcut.events.append(input_key)
						node.shortcut = shortcut

			node.disabled = not enabled

			if node.pressed.is_connected(_on_ChoiceButton_choice_selected):
				node.pressed.disconnect(_on_ChoiceButton_choice_selected)

			node.pressed.connect(_on_ChoiceButton_choice_selected.bind(event_index,
				{'button_index':button_index, 'text':text, 'enabled':enabled, 'event_index':event_index}))
			shown_at_all = true

		if node.choice_index > 0:
			idx = node.choice_index
		idx += 1

	if not shown_at_all:
		printerr("[Dialogic] The layout you are using doesn't have enough Choice Buttons for the choices you are trying to display.")


func _on_ChoiceButton_choice_selected(event_index:int, choice_info:={}) -> void:
	if dialogic.paused or not _choice_blocker.is_stopped():
		return

	choice_selected.emit(choice_info)
	hide_all_choices()
	dialogic.current_state = dialogic.States.IDLE
	dialogic.handle_event(event_index+1)

	if dialogic.has_subsystem('History'):
		var all_choices: Array = dialogic.Choices.last_question_info['choices']
		if dialogic.has_subsystem('VAR'):
			dialogic.History.store_simple_history_entry(dialogic.VAR.parse_variables(choice_info.text), "Choice", {'all_choices': all_choices})
		else:
			dialogic.History.store_simple_history_entry(choice_info.text, "Choice", {'all_choices': all_choices})



func get_current_choice_indexes() -> Array:
	var choices := []
	var evt_idx := dialogic.current_event_idx
	var ignore := 0
	while true:
		if evt_idx >= len(dialogic.current_timeline_events):
			break
		if dialogic.current_timeline_events[evt_idx] is DialogicChoiceEvent:
			if ignore == 0:
				choices.append(evt_idx)
			ignore += 1
		elif dialogic.current_timeline_events[evt_idx].can_contain_events:
			ignore += 1
		else:
			if ignore == 0:
				break

		if dialogic.current_timeline_events[evt_idx] is DialogicEndBranchEvent:
			ignore -= 1
		evt_idx += 1
	return choices

#endregion


#region HELPERS
####################################################################################################

func is_question(index:int) -> bool:
	if dialogic.current_timeline_events[index] is DialogicTextEvent:
		if len(dialogic.current_timeline_events)-1 != index:
			if dialogic.current_timeline_events[index+1] is DialogicChoiceEvent:
				return true

	if dialogic.current_timeline_events[index] is DialogicChoiceEvent:
		if index != 0 and dialogic.current_timeline_events[index-1] is DialogicEndBranchEvent:
			if dialogic.current_timeline_events[dialogic.current_timeline_events[index-1].find_opening_index()] is DialogicChoiceEvent:
				return false
			else:
				return true
		else:
			return true
	return false

#endregion
