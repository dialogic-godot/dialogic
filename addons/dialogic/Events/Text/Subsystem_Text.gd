extends DialogicSubsystem

# used to color names without searching for all characters each time
var character_colors := {}
var color_regex := RegEx.new()

signal text_finished
signal speaking_character(argument)

####################################################################################################
##					STATE
####################################################################################################
func clear_game_state() -> void:
	update_dialog_text('')
	update_name_label(null)
	dialogic.current_state_info['character'] = null
	dialogic.current_state_info['text'] = ''

func load_game_state() -> void:
	update_dialog_text(dialogic.current_state_info.get('text', ''))
	var character:DialogicCharacter = null
	if dialogic.current_state_info.get('character', null):
		character = load(dialogic.current_state_info.get('character', null))
	
	if character:
		update_name_label(character)

func pause() -> void:
	for text_node in get_tree().get_nodes_in_group('dialogic_dialog_text'):
		if text_node.is_visible_in_tree():
			text_node.pause()

func resume() -> void:
	for text_node in get_tree().get_nodes_in_group('dialogic_dialog_text'):
		if text_node.is_visible_in_tree():
			text_node.resume()
	
####################################################################################################
##					MAIN METHODS
####################################################################################################

func update_dialog_text(text:String) -> void:
	dialogic.current_state = dialogic.states.SHOWING_TEXT
	dialogic.current_state_info['text'] = text
	for text_node in get_tree().get_nodes_in_group('dialogic_dialog_text'):
		if text_node.is_visible_in_tree():
			text_node.reveal_text(text)
			if !text_node.finished_revealing_text.is_connected(_on_dialog_text_finished):
				text_node.finished_revealing_text.connect(_on_dialog_text_finished)

func _on_dialog_text_finished():
	text_finished.emit()

func update_name_label(character:DialogicCharacter) -> void:
	for name_label in get_tree().get_nodes_in_group('dialogic_name_label'):
		if character:
			dialogic.current_state_info['character'] = character.resource_path
			if dialogic.has_subsystem('VAR'):
				name_label.text = dialogic.VAR.parse_variables(character.display_name)
			else:
				name_label.text = character.display_name
			if !'use_character_color' in name_label or name_label.use_character_color:
				name_label.self_modulate = character.color
			speaking_character.emit(name_label.text)
		else:
			dialogic.current_state_info['character'] = null
			name_label.text = ''
			name_label.self_modulate = Color(1,1,1,1)
			speaking_character.emit("(Nobody)")

func update_typing_sound_mood(mood:Dictionary = {}) -> void:
	for typing_sound in get_tree().get_nodes_in_group('dialogic_type_sounds'):
		typing_sound.load_overwrite(mood)
		
func hide_text_boxes() -> void:
	for name_label in get_tree().get_nodes_in_group('dialogic_name_label'):
		name_label.text = ""
	for text_node in get_tree().get_nodes_in_group('dialogic_dialog_text'):
		text_node.get_parent().visible = false
		
func show_text_boxes() -> void:
	for text_node in get_tree().get_nodes_in_group('dialogic_dialog_text'):
		text_node.get_parent().visible = true

func show_next_indicators(question=false, autocontinue=false) -> void:
	for next_indicator in get_tree().get_nodes_in_group('dialogic_next_indicator'):
		if (question and 'show_on_questions' in next_indicator and next_indicator.show_on_questions) or \
			(autocontinue and 'show_on_autocontinue' in next_indicator and next_indicator.show_on_autocontinue) or (!question and !autocontinue):
			next_indicator.show()

func hide_next_indicators(fake_arg=null) -> void:
	for next_indicator in get_tree().get_nodes_in_group('dialogic_next_indicator'):
		next_indicator.hide()

####################################################################################################
##					HELPERS
####################################################################################################
func skip_text_animation() -> void:
	for text_node in get_tree().get_nodes_in_group('dialogic_dialog_text'):
		if text_node.is_visible_in_tree():
			text_node.finish_text()
	if dialogic.has_subsystem('Voice'):
		dialogic.Voice.stop_audio()

func get_current_speaker() -> DialogicCharacter:
	return (load(dialogic.current_state_info['character']) as DialogicCharacter)


func _ready():
	update_character_names()
	Dialogic.event_handled.connect(hide_next_indicators)


func color_names(text:String) -> String:
	if !DialogicUtil.get_project_setting('dialogic/text/autocolor_names', false):
		return text

	var counter = 0
	for result in color_regex.search_all(text):
		text = text.insert(result.get_start("name")+((9+8+8)*counter), '[color=#' + character_colors[result.get_string('name')].to_html() + ']')
		text = text.insert(result.get_end("name")+9+8+((9+8+8)*counter), '[/color]')
		counter += 1
	
	return text

func update_character_names() -> void:
	#don't do this at all if we're not using autocolor names to begin with
	if !DialogicUtil.get_project_setting('dialogic/text/autocolor_names', false):
		return 
	
	character_colors = {}
	for dch_path in DialogicUtil.list_resources_of_type('.dch'):
		var dch = (load(dch_path) as DialogicCharacter)
#
		if dch.name: character_colors[dch.name] = dch.color
		for nickname in dch.nicknames:
			if nickname.strip_edges(): character_colors[nickname.strip_edges()] = dch.color
	
	color_regex.compile('(?<=\\W)(?<name>'+str(character_colors.keys()).trim_prefix('[').trim_suffix(']').replace(', ', '|')+')(?=\\W|$)')
	
