extends DialogicSubsystem

## Subsystem that manages showing and activating of choices.

signal choice_selected(info:Dictionary)
signal choices_shown(info:Dictionary)


## Used to block choices from being clicked for a couple of seconds (if delay is set in settings).
var choice_blocker := Timer.new()

var last_question_info := {}

func _ready():
	choice_blocker.one_shot = true
	DialogicUtil.update_timer_process_callback(choice_blocker)
	add_child(choice_blocker)


####################################################################################################
##					STATE
####################################################################################################

func clear_game_state(clear_flag:=Dialogic.ClearFlags.FULL_CLEAR):
	hide_all_choices()


####################################################################################################
##					MAIN METHODS
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
	choice_blocker.stop()
	
	var reveal_delay := float(ProjectSettings.get_setting('dialogic/choices/reveal_delay', 0.0))
	var reveal_by_input :bool = ProjectSettings.get_setting('dialogic/choices/reveal_by_input', false)
	
	if !instant and (reveal_delay != 0 or reveal_by_input):
		if reveal_delay != 0:
			choice_blocker.start(reveal_delay)
			choice_blocker.timeout.connect(show_current_choices)
		if reveal_by_input:
			Dialogic.Text.input_handler.dialogic_action.connect(show_current_choices)
		return
	
	if choice_blocker.timeout.is_connected(show_current_choices):
		choice_blocker.timeout.disconnect(show_current_choices)
	if Dialogic.Text.input_handler.dialogic_action.is_connected(show_current_choices):
		Dialogic.Text.input_handler.dialogic_action.disconnect(show_current_choices)
	
	
	var button_idx := 1
	last_question_info = {'choices':[]}
	for choice_index in get_current_choice_indexes():
		var choice_event :DialogicEvent= dialogic.current_timeline_events[choice_index]
		# check if condition is false
		if not choice_event.condition.is_empty() and not dialogic.Expression.execute_condition(choice_event.condition):
			if choice_event.else_action == DialogicChoiceEvent.ElseActions.DEFAULT:
				choice_event.else_action = ProjectSettings.get_setting('dialogic/choices/def_false_behaviour', 0)
			
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
	choice_blocker.start(float(ProjectSettings.get_setting('dialogic/choices/delay', 0.2)))


## Adds a button with the given text that leads to the given event.
func show_choice(button_index:int, text:String, enabled:bool, event_index:int) -> void:
	var idx := 1
	for node in get_tree().get_nodes_in_group('dialogic_choice_button'):
		if !node.get_parent().is_visible_in_tree():
			continue
		if (node.choice_index == button_index) or (idx == button_index and node.choice_index == -1):
			node.show()
			if dialogic.has_subsystem('VAR'):
				node.text = dialogic.VAR.parse_variables(text)
			else:
				node.text = text
			
			if idx == 1 and ProjectSettings.get_setting('dialogic/choices/autofocus_first', true):
				node.grab_focus()
			
			if ProjectSettings.get_setting('dialogic/choices/hotkey_behaviour', 0) == 1 and idx < 10:
				var shortcut := Shortcut.new()
				var input_key := InputEventKey.new()
				input_key.scancode = OS.find_keycode_from_string(str(idx))
				shortcut.shortcut = input_key
				node.shortcut = shortcut
			
			node.disabled = not enabled
			node.button_up.connect(_on_ChoiceButton_choice_selected.bind(event_index, 
				{'button_index':button_index, 'text':text, 'enabled':enabled, 'event_index':event_index}))
			
		if node.choice_index > 0:
			idx = node.choice_index
		idx += 1


func _on_ChoiceButton_choice_selected(event_index:int, choice_info:={}) -> void:
	if Dialogic.paused or not choice_blocker.is_stopped():
		return
	choice_selected.emit(choice_info)
	hide_all_choices()
	dialogic.current_state = dialogic.States.IDLE
	dialogic.handle_event(event_index)
	

func get_current_choice_indexes() -> Array:
	var choices := []
	var evt_idx :int= dialogic.current_event_idx
	var ignore := 0
	while true:
		
		evt_idx += 1
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
	return choices

####################################################################################################
##					HELPERS
####################################################################################################

func is_question(index:int) -> bool:
	if dialogic.current_timeline_events[index] is DialogicTextEvent:
		if len(dialogic.current_timeline_events)-1 != index:
			if dialogic.current_timeline_events[index+1] is DialogicChoiceEvent:
				return true
	return false

