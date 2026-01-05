extends DialogicSubsystem

## Subsystem that manages showing and activating of choices.

## Emitted when a choice button was pressed. Info includes the keys 'button_index', 'text', 'event_index'.
signal choice_selected(info:Dictionary)
## Emitted when a set of choices is reached and shown.
## Info includes the keys 'choices' (an array of dictionaries with infos on all the choices).
signal question_shown(info:Dictionary)
## Emitted when a question was reached that has no usable choice (all hidden or disabled).
signal invalid_question_reached

## Contains information on the latest question. See [method get_current_question_info] for info on content.
var last_question_info := {}

## The delay between the text finishing revealing and the choices appearing
var reveal_delay := 0.0
## If true the player has to click to reveal choices when they are reached
var reveal_by_input := false
## The delay between the choices becoming visible and being clickable. Can prevent accidental selection.
var block_delay := 0.2
## If true, the first (top-most) choice will be focused
var autofocus_first_choice := true
## If true the dialogic input action is used to trigger choices.
## However mouse events will be ignored no matter what.
var use_input_action := false

enum FalseBehaviour {HIDE=0, DISABLE=1}
## The behaviour of choices with a false condition and else_action set to DEFAULT.
var default_false_behaviour := FalseBehaviour.HIDE

enum HotkeyBehaviour {NONE, NUMBERS}
## Will add some hotkeys to the choices if different then HotkeyBehaviour.NONE.
var hotkey_behaviour := HotkeyBehaviour.NONE

enum InvalidChoiceBehaviour {NOTHING, AUTO_SKIP}
var invalid_choice_behaviour := InvalidChoiceBehaviour.AUTO_SKIP
### INTERNALS

## Used to block choices from being clicked for a couple of seconds (if delay is set in settings).
var _choice_blocker := Timer.new()

#region STATE
####################################################################################################

func clear_game_state(_clear_flag:=DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
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


func post_install() -> void:
	dialogic.Inputs.dialogic_action.connect(_on_dialogic_action)

#endregion


#region MAIN METHODS
####################################################################################################

## Hides all choice buttons.
func hide_all_choices() -> void:
	for node in get_tree().get_nodes_in_group('dialogic_choice_button'):
		node.hide()
		if node.choice_selected.is_connected(_on_choice_selected):
			node.choice_selected.disconnect(_on_choice_selected)


## Collects information on all the choices of the current question.
## The result is a dictionary like this:
## {'choices':
##	[
##		{'event_index':10, 'button_index':1, 'disabled':false, 'text':"My Choice", 'visible':true},
##		{'event_index':15, 'button_index':2, 'disabled':false, 'text':"My Choice2", 'visible':true},
##	]
## 'invalid':false # is true if all choices are either invisible or disabled
## }
func get_current_question_info() -> Dictionary:
	var question_info := {'choices':[]}

	var button_idx := 1
	var any_valid := false
	for choice_index in get_current_choice_indexes():
		var event: DialogicEvent = dialogic.current_timeline_events[choice_index]

		if not event is DialogicChoiceEvent:
			continue

		var choice_event: DialogicChoiceEvent = event
		var choice_info := {}
		choice_info['event_index'] = choice_index
		choice_info['button_index'] = button_idx

		# Check Condition
		var condition: String = choice_event.condition

		if condition.is_empty() or dialogic.Expressions.execute_condition(choice_event.condition):
			any_valid = true
			choice_info['disabled'] = false
			choice_info['text'] = choice_event.get_property_translated('text')
			choice_info['visible'] = true
			button_idx += 1
		else:
			choice_info['disabled'] = true
			if not choice_event.disabled_text.is_empty():
				choice_info['text'] = choice_event.get_property_translated('disabled_text')
			else:
				choice_info['text'] = choice_event.get_property_translated('text')

			var hide := choice_event.else_action == DialogicChoiceEvent.ElseActions.HIDE
			hide = hide or choice_event.else_action == DialogicChoiceEvent.ElseActions.DEFAULT and default_false_behaviour == DialogicChoiceEvent.ElseActions.HIDE
			choice_info['visible'] = not hide

			if not hide:
				button_idx += 1

		choice_info.text = dialogic.Text.parse_text(choice_info.text, 1)

		choice_info.merge(choice_event.extra_data)

		if dialogic.has_subsystem('History'):
			choice_info['visited_before'] = dialogic.History.has_event_been_visited(choice_index)

		question_info['choices'].append(choice_info)

	question_info["invalid"] = not any_valid
	return question_info


## Lists all current choices and shows buttons.
func show_current_question(instant:=true) -> void:
	hide_all_choices()
	_choice_blocker.stop()
	last_question_info = get_current_question_info()

	if !instant and (reveal_delay != 0 or reveal_by_input):
		if reveal_delay != 0:
			_choice_blocker.start(reveal_delay)
			_choice_blocker.timeout.connect(show_current_question)
		if reveal_by_input:
			dialogic.Inputs.dialogic_action.connect(show_current_question)
		return

	if _choice_blocker.timeout.is_connected(show_current_question):
		_choice_blocker.timeout.disconnect(show_current_question)
	if dialogic.Inputs.dialogic_action.is_connected(show_current_question):
		dialogic.Inputs.dialogic_action.disconnect(show_current_question)

	var missing_button := false

	var question_info := get_current_question_info()

	for choice in question_info.choices:
		var node: DialogicNode_ChoiceButton = get_choice_button(choice.button_index)

		if not node:
			missing_button = true
			continue

		node._load_info(choice)


		if choice.button_index == 1 and autofocus_first_choice:
			node.grab_focus()

		match hotkey_behaviour:
			## Add 1 to 9 as shortcuts if it's enabled
			HotkeyBehaviour.NUMBERS:
				if choice.button_index > 0 or choice.button_index < 10:
					var shortcut: Shortcut
					if node.shortcut != null:
						shortcut = node.shortcut
					else:
						shortcut = Shortcut.new()

					var input_key := InputEventKey.new()
					input_key.keycode = OS.find_keycode_from_string(str(choice.button_index))
					shortcut.events.append(input_key)
					node.shortcut = shortcut

		if node.choice_selected.is_connected(_on_choice_selected):
			node.choice_selected.disconnect(_on_choice_selected)
		node.choice_selected.connect(_on_choice_selected.bind(choice))

	_choice_blocker.start(block_delay)
	question_shown.emit(question_info)
	if question_info.invalid:
		invalid_question_reached.emit()
		printerr("[Dialogic] An invalid question was reached (all choices disabled or invisible).")
		dialogic.print_debug_moment()
		if invalid_choice_behaviour == InvalidChoiceBehaviour.AUTO_SKIP:
			skip_question()

	if missing_button:
		printerr("[Dialogic] The layout you are using doesn't have enough Choice Buttons for the choices you are trying to display.")


## Skips to the end of the current question.
func skip_question() -> void:
	if not last_question_info:
		return
	hide_all_choices()
	dialogic.current_state = dialogic.States.IDLE
	dialogic.current_event_idx = dialogic.current_timeline.get_event(last_question_info.choices[0].event_index).get_end_branch_index()-1
	dialogic.handle_next_event()


func focus_choice(button_index:int) -> void:
	var node: DialogicNode_ChoiceButton = get_choice_button(button_index)
	if node:
		node.grab_focus()


func select_choice(button_index:int) -> void:
	var node: DialogicNode_ChoiceButton = get_choice_button(button_index)
	if node:
		node.choice_selected.emit()


func select_focused_choice() -> void:
	if get_viewport().gui_get_focus_owner() is DialogicNode_ChoiceButton:
		(get_viewport().gui_get_focus_owner() as DialogicNode_ChoiceButton).choice_selected.emit()


func get_choice_button(button_index:int) -> DialogicNode_ChoiceButton:
	var idx := 1
	for node: DialogicNode_ChoiceButton in get_tree().get_nodes_in_group('dialogic_choice_button'):
		if !node.get_parent().is_visible_in_tree():
			continue
		if node.choice_index == button_index or (node.choice_index == -1 and idx == button_index):
			return node

		if node.choice_index > 0:
			idx = node.choice_index
		idx += 1
	return null


func _on_choice_selected(choice_info := {}) -> void:
	if dialogic.paused or not _choice_blocker.is_stopped():
		return

	if dialogic.has_subsystem('History'):
		var all_choices: Array = last_question_info['choices'].map(func(x): return x["text"])
		if dialogic.has_subsystem('VAR'):
			dialogic.History.store_simple_history_entry(dialogic.VAR.parse_variables(choice_info.text), "Choice", {'all_choices': all_choices})
		else:
			dialogic.History.store_simple_history_entry(choice_info.text, "Choice", {'all_choices': all_choices})
		if dialogic.has_subsystem("History"):
			dialogic.History.mark_event_as_visited(choice_info.event_index)

	choice_selected.emit(choice_info)
	hide_all_choices()
	dialogic.current_state = dialogic.States.IDLE
	dialogic.handle_event(choice_info.event_index + 1)


## Returns the indexes of the choice events related to the current question.
func get_current_choice_indexes() -> Array:
	var choices := []
	var index := dialogic.current_event_idx-1
	while true:
		index += 1
		if index >= len(dialogic.current_timeline_events):
			break

		var event: DialogicEvent = dialogic.current_timeline_events[index]
		if event is DialogicChoiceEvent:
			choices.append(index)
			index = event.get_end_branch_index()
		else:
			break

	return choices


## Forward the dialogic action to the focused button
func _on_dialogic_action() -> void:
	if use_input_action and not dialogic.Inputs.input_was_mouse_input:
		select_focused_choice()


#endregion


#region HELPERS
####################################################################################################

## Returns `true` if the given index is a text event before a question or the first choice event of a question.
func is_question(index:int) -> bool:
	var event: DialogicEvent = dialogic.current_timeline_events[index]
	if event is DialogicTextEvent:
		if len(dialogic.current_timeline_events)-1 != index:
			var next_event: DialogicEvent = dialogic.current_timeline_events[index+1]
			if next_event is DialogicChoiceEvent:
				return true

	if event is DialogicChoiceEvent:
		if index == 0:
			return true
		var prev_event: DialogicEvent = dialogic.current_timeline_events[index-1]
		if not prev_event is DialogicEndBranchEvent:
			return true
		var prev_event_opener: DialogicEvent = dialogic.current_timeline_events[prev_event.get_opening_index()]
		if prev_event_opener is DialogicChoiceEvent:
			return false
		else:
			return true

	return false

#endregion
