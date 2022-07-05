extends DialogicSubsystem


####################################################################################################
##					STATE
####################################################################################################

func clear_game_state():
	hide_all_choices()

func load_game_state():
	pass

####################################################################################################
##					MAIN METHODS
####################################################################################################

func hide_all_choices() -> void:
	for node in get_tree().get_nodes_in_group('dialogic_choice_button'):
		node.hide()
		if node.is_connected('pressed', self, 'choice_selected'):
			node.disconnect('pressed', self, 'choice_selected')

func show_current_choices() -> void:
	hide_all_choices()
	var button_idx = 1
	for choice_index in get_current_choice_indexes():
		var choice_event = dialogic.current_timeline_events[choice_index]
		# check if condition is false
		if not choice_event.Condition.empty() and not dialogic.execute_condition(choice_event.Condition):
			# check what to do in this case
			if choice_event.IfFalseAction == DialogicChoiceEvent.IfFalseActions.DISABLE:
				show_choice(button_idx, choice_event.get_translated_text(), false, choice_index)
				button_idx += 1
		# else just show it
		else:
			show_choice(button_idx, choice_event.get_translated_text(), true, choice_index)
			button_idx += 1

func show_choice(button_index:int, text:String, enabled:bool, event_index:int) -> void:
	var idx = 1
	for node in get_tree().get_nodes_in_group('dialogic_choice_button'):
		if !node.get_parent().is_visible_in_tree():
			continue
		if (node.choice_index == button_index) or (idx == button_index and node.choice_index == -1):
			node.show()
			node.text = dialogic.parse_variables(text)
			node.disabled = not enabled
			node.connect('pressed', self, 'choice_selected', [event_index])
		if node.choice_index >0:
			idx = node.choice_index
		idx += 1

####################################################################################################
##					HELPERS
####################################################################################################
func choice_selected(event_index:int) -> void:
	hide_all_choices()
	dialogic.current_state = dialogic.states.IDLE
	dialogic.handle_event(event_index)

## QUESTION/CHOICES
func is_question(index:int) -> bool:
	if dialogic.current_timeline_events[index] is DialogicTextEvent:
		if len(dialogic.current_timeline_events)-1 != index:
			if dialogic.current_timeline_events[index+1] is DialogicChoiceEvent:
				return true
	return false

func get_current_choice_indexes() -> Array:
	var choices = []
	var evt_idx = dialogic.current_event_idx
	var ignore = 0
	while true:
		
		evt_idx += 1
		if evt_idx >= len(dialogic.current_timeline_events):
			break
		if dialogic.current_timeline_events[evt_idx] is DialogicChoiceEvent:
			if ignore == 0:
				choices.append(evt_idx)
			ignore += 1
		if dialogic.current_timeline_events[evt_idx] is DialogicConditionEvent:
			ignore += 1
		else:
			if ignore == 0:
				break
		
		if dialogic.current_timeline_events[evt_idx] is DialogicEndBranchEvent:
			ignore -= 1
	return choices
