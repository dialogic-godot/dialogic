extends DialogicSubsystem



####################################################################################################
##					STATE
####################################################################################################

func clear_game_state():
	for portrait in dialogic.current_state_info.get('portraits', []):
		remove_portrait(portrait.character)
	dialogic.current_state_info['portraits'] = {}

func load_game_state():
	for portrait in dialogic.current_state_info['portraits']:
		add_portrait(portrait.character, portrait.portrait, portrait.position_idx)


####################################################################################################
##					MAIN METHODS
####################################################################################################

func add_portrait(character:DialogicCharacter, portrait:String,  position_idx:int) -> Node:
	var portrait_node = null
	
	if not character:
		assert(false, "[Dialogic] Cannot add portrait of null character.")
	if not portrait in character.portraits:
		assert(false, "[Dialogic] Character "+ character.display_name+ " has no portrait '"+portrait+"'.")
	if len(get_tree().get_nodes_in_group('dialogic_portrait_holder')) == 0:
		assert(false, '[Dialogic] If you want to display portraits, you need a PortraitHolder scene!')
	
	for node in get_tree().get_nodes_in_group('dialogic_portrait_position'):
		if node.position_index == position_idx:
			var path = character.portraits[portrait].path
			if not path.ends_with('.tscn'):
				var sprite = Sprite.new()
				get_tree().get_nodes_in_group('dialogic_portrait_holder')[0].add_child(sprite)
				sprite.texture = load(path)
				sprite.centered = false
				sprite.scale = Vector2(1,1)*character.portraits[portrait].scale
				sprite.global_position = node.global_position + character.portraits[portrait].offset
				sprite.global_position.x -= sprite.texture.get_width()/2.0*character.portraits[portrait].scale*character.scale
				sprite.global_position.y -= sprite.texture.get_height()*character.portraits[portrait].scale*character.scale
				portrait_node = sprite
	
	if portrait_node:
		dialogic.current_state_info['portraits'][character.resource_path] = {'portrait':portrait, 'node':portrait_node, 'position_index':position_idx}
	
	return portrait_node

func change_portrait(character:DialogicCharacter, portrait:String) -> void:
	if not character or not is_character_joined(character):
		assert(false, "[Dialogic] Cannot change portrait of null/not joined character.")
	
	var portrait_node = dialogic.current_state_info.portraits[character.resource_path].node
	
	if 'does_custom_portrait_change' in portrait_node and portrait_node.does_custom_portrait_change():
		portrait_node.change_portrait(character, portrait)
	else:
		dialogic.current_state_info['portraits'][character.resource_path].node.queue_free()
		add_portrait(character, portrait, dialogic.current_state_info['portraits'][character.resource_path].position_index)


func animate_portrait(portrait_node, animation):
	pass

func move_portrait(character:DialogicCharacter, position_idx:int, tween:bool= false, time:float = 1):
	if not character or not is_character_joined(character):
		assert(false, "[Dialogic] Cannot move portrait of null/not joined character.")
	
	var portrait_node = dialogic.current_state_info.portraits[character.resource_path].node
	
	for node in get_tree().get_nodes_in_group('dialogic_portrait_position'):
		if node.position_index == position_idx:
			if not tween:
				portrait_node.global_position = node.global_position
	
	dialogic.current_state_info.portraits[character.resource_path].position_index = position_idx

func set_portrait_z_index(portrait_node, z_index):
	pass

func remove_portrait(character:DialogicCharacter) -> void:
	dialogic.current_state_info['portraits'][character.resource_path].node.queue_free()
	dialogic.current_state_info['portraits'].erase(character.resource_path)


####################################################################################################
##					HELPERS
####################################################################################################

func is_character_joined(character:DialogicCharacter) -> bool:
	return character.resource_path in dialogic.current_state_info['portraits']

func get_joined_characters() -> Array:
	var chars = []
	for char_path in dialogic.current_state_info.get('portraits', {}).keys():
		chars.append(load(char_path))
	return chars
