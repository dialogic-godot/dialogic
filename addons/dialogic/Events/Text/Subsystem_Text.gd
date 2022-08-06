extends DialogicSubsystem

# used to color names without searching for all characters each time
var character_colors = {}
var color_regex = RegEx.new()
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
		if character:
			dialogic.current_state_info['character'] = character.resource_path
			name_label.text = character.display_name
			if !'use_character_color' in name_label or name_label.use_character_color:
				name_label.self_modulate = character.color
		else:
			dialogic.current_state_info['character'] = null
			name_label.text = ''
			name_label.self_modulate = Color(1,1,1,1)

func update_typing_sound_mood(mood:Dictionary = {}) -> void:
	for typing_sound in get_tree().get_nodes_in_group('dialogic_type_sounds'):
		typing_sound.load_overwrite(mood)

####################################################################################################
##					HELPERS
####################################################################################################
func skip_text_animation() -> void:
	for text_node in get_tree().get_nodes_in_group('dialogic_dialog_text'):
		if text_node.is_visible_in_tree():
			text_node.finish_text()
	if dialogic.has_subsystem('Voice'):
		dialogic.Voice.stopAudio()

func get_current_speaker() -> DialogicCharacter:
	return (load(dialogic.current_state_info['character']) as DialogicCharacter)


func _ready():
	update_character_names()

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
	
