extends DialogicSubsystem


####################################################################################################
##					STATE
####################################################################################################

func clear_game_state():
	update_dialog_text('')
	update_name_label(null)
	dialogic.current_state_info['character'] = null
	dialogic.current_state_info['text'] = ''


func load_game_state():
	update_dialog_text(dialogic.current_state_info.get('text', ''))
	var character:DialogicCharacter = null
	if dialogic.current_state_info.get('character', null):
		character = load(dialogic.current_state_info.get('character', null))
	
	if character:
		update_name_label(character)

####################################################################################################
##					MAIN METHODS
####################################################################################################

func update_dialog_text(text:String) -> void:
	dialogic.current_state = dialogic.states.SHOWING_TEXT
	dialogic.current_state_info['text'] = text
	for text_node in get_tree().get_nodes_in_group('dialogic_dialog_text'):
		if text_node.is_visible_in_tree():
			text_node.reveal_text(text)


func update_name_label(character:DialogicCharacter) -> void:
	for name_label in get_tree().get_nodes_in_group('dialogic_name_label'):
		if name_label.is_visible_in_tree():
			if character:
				dialogic.current_state_info['character'] = character.resource_path
				name_label.text = character.display_name
				name_label.self_modulate = character.color
			else:
				dialogic.current_state_info['character'] = null
				name_label.text = ''
				name_label.self_modulate = Color.white


####################################################################################################
##					HELPERS
####################################################################################################
func skip_text_animation() -> void:
	for text_node in get_tree().get_nodes_in_group('dialogic_dialog_text'):
		if text_node.is_visible_in_tree():
			text_node.finish_text()

func get_current_speaker() -> DialogicCharacter:
	return (load(dialogic.current_state_info['character']) as DialogicCharacter)
