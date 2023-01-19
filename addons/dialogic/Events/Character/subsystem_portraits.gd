extends DialogicSubsystem

## Subsystem that manages portraits and portrait positions.

## The default portrait scene.
var default_portrait_scene = load(get_script().resource_path.get_base_dir().path_join('default_portrait.tscn'))
## Temporarily stores the default positions.
var _default_positions: Dictionary = {}
## Stores the current positions.
var current_positions: Dictionary = {}

## A reference to the current [DialogicNode_PortraitHolder].
var _portrait_holder_reference: Node = null

####################################################################################################
##					STATE
####################################################################################################

func clear_game_state():
	for character in dialogic.current_state_info.get('portraits', {}).keys():
		remove_portrait(load(character))
	dialogic.current_state_info['portraits'] = {}


func load_game_state():
	for character_path in dialogic.current_state_info['portraits']:
		add_portrait(
			load(character_path), 
			dialogic.current_state_info['portraits'][character_path].portrait, dialogic.current_state_info['portraits'][character_path].position_index,
			false)


func pause() -> void:
	for portrait in dialogic.current_state_info['portraits'].values():
		if portrait.has('animation_node'):
			portrait.animation_node.pause()


func resume() -> void:
	for portrait in dialogic.current_state_info['portraits'].values():
		if portrait.has('animation_node'):
			portrait.animation_node.resume()


####################################################################################################
##					MAIN METHODS
####################################################################################################

## Joins a character and then calls change_portrait().
func add_portrait(character:DialogicCharacter, portrait:String,  position_idx:int, mirrored: bool = false, z_index: int = 0, extra_data:String = "") -> Node:
	var character_node = null
	
	if portrait.is_empty():
		portrait = character.default_portrait
	
	if not character:
		print_debug('[DialogicError] Cannot call add_portrait() with null character.')
		return null
	if not portrait in character.portraits:
		print_debug("[DialogicError] Tried joining ",character.display_name, " with not-existing portrait '", portrait, "'. Will use default portrait instead.")
		portrait = character.default_portrait
		if portrait.is_empty():
			print_debug("[DialogicError] Character ",character.display_name, " has no default portrait to use.")
			return null
	
	check_positions_and_holder()

	character_node = Node2D.new()
	character_node.name = character.get_character_name()
	character_node.position = current_positions[position_idx]
	character_node.z_index = z_index
	character_node.set_meta("position", position_idx)
	_portrait_holder_reference.add_child(character_node)
	
	if character_node:
		dialogic.current_state_info['portraits'][character.resource_path] = {'portrait':portrait, 'node':character_node, 'position_index':position_idx}
	if portrait:
		change_portrait(character, portrait, mirrored, z_index, false, extra_data)
	
	return character_node

## Changes the portrait of a character. Only works with characters that joined previously.
func change_portrait(character:DialogicCharacter, portrait:String, mirrored:bool = false, z_index: int = 0, update_zindex:bool = false, extra_data:String = "") -> void:
	if not character or not is_character_joined(character):
		print_debug('[DialogicError] Cannot change portrait of null/not joined character.')
		return
	
	if portrait.is_empty():
		portrait = character.default_portrait
	
	if not portrait in character.portraits.keys():
		print_debug('[Dialogic] Change to not-existing portrait will be ignored!')
		return
	
	var char_node :Node = dialogic.current_state_info.portraits[character.resource_path].node
	
	if update_zindex:
		char_node.z_index = z_index
	
	# path to the scene to use
	var scene_path :String = character.portraits[portrait].get('scene', '')
	
	var portrait_node = null
	
	# check if the scene is the same as the currently loaded scene
	if (char_node.get_child_count() and 
		character.portraits[dialogic.current_state_info['portraits'][character.resource_path]['portrait']].get('scene', '') == scene_path and 
		# also check if the scene supports changing to the given portrait
		(!char_node.get_child(0).has_method('_should_do_portrait_update') or char_node.get_child(0)._should_do_portrait_update(character, portrait))):
			portrait_node = char_node.get_child(0)
	else:
		# remove previous portrait
		if char_node.get_child_count():
			char_node.get_child(0).queue_free()

		if scene_path.is_empty():
			portrait_node = default_portrait_scene.instantiate()
		else:
			var p = load(scene_path)
			if p:
				portrait_node = p.instantiate()
			else:
				push_error('Dialogic: Portrait node "' + str(scene_path) + '" for character [' + character.display_name + '] could not be loaded. Your portrait might not show up on the screen.')
	
	if portrait_node:
		portrait_node.position = character.offset + character.portraits[portrait].get('offset', Vector2())
		
		# ignore the character scale on custom portraits that have 'ignore_char_scale' set to true
		if scene_path.is_empty() or !character.portraits[portrait].get('ignore_char_scale', false):
			portrait_node.scale = Vector2(1,1)*character.scale * character.portraits[portrait].get('scale', 1)
		else:
			portrait_node.scale = Vector2(1,1)*character.portraits[portrait].get('scale', 1)
		
		for property in character.portraits[portrait].get('export_overrides', {}).keys():
			portrait_node.set(property, str_to_var(character.portraits[portrait]['export_overrides'][property]))
		
		if portrait_node.has_method('_update_portrait'):
			portrait_node._update_portrait(character, portrait)
		if portrait_node.has_method('_set_mirror'):
			portrait_node._set_mirror(mirrored)
		if portrait_node.has_method('_set_extra_data'):
			portrait_node._set_extra_data(extra_data)
		
		if !portrait_node.is_inside_tree():
			char_node.add_child(portrait_node)
	dialogic.current_state_info['portraits'][character.resource_path]['portrait'] = portrait

## Animates the portrait of the given character with the given animation.
func animate_portrait(character:DialogicCharacter, animation_path:String, length:float, repeats = 1) -> DialogicAnimation:
	if not character or not is_character_joined(character):
		print_debug('[DialogicError] Cannot animate portrait of null/not joined character.')
		return null
	
	var char_node = dialogic.current_state_info['portraits'][character.resource_path].node
	
	if dialogic.current_state_info['portraits'][character.resource_path].get('animation_node', null):
		if is_instance_valid(dialogic.current_state_info['portraits'][character.resource_path].animation_node):
			dialogic.current_state_info['portraits'][character.resource_path].animation_node.queue_free()
	var anim_script = load(animation_path)
	var anim_node = Node.new()
	anim_node.set_script(anim_script)
	anim_node = (anim_node as DialogicAnimation)
	anim_node.node = char_node
	anim_node.orig_pos = char_node.position
	anim_node.end_position = char_node.position
	anim_node.time = length
	anim_node.repeats = repeats
	add_child(anim_node)
	anim_node.animate()
	dialogic.current_state_info['portraits'][character.resource_path]['animation_node'] = anim_node
	return anim_node


## Moves the portrait of the given character to the given positions. Also allows updating the z_index.
## TODO: Question, why the z_index is set here and in change_portrait and doesn't have it's own method.
func move_portrait(character:DialogicCharacter, position_idx:int, z_index:int = 0, update_zindex:bool = false,  time:float = 0.0):
	if not character or not is_character_joined(character):
		print_debug('[DialogicError] Cannot move portrait of null/not joined character.')
		return
	
	var char_node = dialogic.current_state_info.portraits[character.resource_path].node
	
	if update_zindex:
		char_node.z_index = z_index
	
	char_node.set_meta('position', position_idx)
	
	if time == 0.0:
		char_node.position = current_positions[position_idx]
	else:
		var tween = char_node.create_tween()
		tween.tween_property(char_node, "position", current_positions[position_idx], time)
	
	dialogic.current_state_info.portraits[character.resource_path].position_index = position_idx


func remove_portrait(character:DialogicCharacter) -> void:
	dialogic.current_state_info['portraits'][character.resource_path].node.queue_free()
	dialogic.current_state_info['portraits'].erase(character.resource_path)


## Creates additional positions either from timeline or at runtime
## If it's an existing position, will move that position to the coordinates instead
## There's no need to actually remove them once added, but saves will need to track position updates as well, so the whole current_positions array will need to be saved
## This will always be an absolute value for new positions, existing positions will be updated as absolute values by this 
func add_portrait_position(position_number: int, position:Vector2) -> void:
	
	check_positions_and_holder()
	
	if position_number in current_positions:
		move_portrait_position(position_number, position)
	else:
		# Add to both current and default positions
		_default_positions[position_number] = position
		current_positions[position_number] = position


func reset_portrait_positions(time:float = 0.0) -> void:
	for position in current_positions:
		move_portrait_position(position, _default_positions[position], false, time)


func reset_portrait_position(position:int, time:float = 0.0) -> void:
	move_portrait_position(position, _default_positions[position], false, time)


func move_portrait_position(position_number: int, vector:Vector2, relative:bool = false, time:float = 0.0) -> void:
	check_positions_and_holder()
	
	if !position_number in current_positions:
		if !relative:
			add_portrait_position(position_number, vector)
		else: 
			print_debug('[DialogicError] Cannot move non-existent position. (Use SetAbsolute to create a new position)')
			return
	
	if !relative:
		current_positions[position_number] = vector
	else:
		current_positions[position_number] += vector
	
	for child in _portrait_holder_reference.get_children():
		if child.get_meta('position') == position_number:
			if time != 0.0:
				var tween = child.create_tween()
				tween.tween_property(child, "position", current_positions[position_number], time)
			else:
				child.position = current_positions[position_number]


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


func update_rpg_portrait_mode(character:DialogicCharacter = null, portrait:String = "") -> void:
	if DialogicUtil.get_project_setting('dialogic/portrait_mode', 0) == DialogicCharacterEvent.PortraitModes.RPG:
		if !Dialogic.current_state_info.has('rpg_last_portrait'):
			Dialogic.current_state_info['rpg_last_portraits'] = {}
		
		if character != null:
			if portrait == "":
				if Dialogic.current_state_info['rpg_last_portraits'].has(character.resource_path):
					portrait = Dialogic.current_state_info['rpg_last_portraits'][character.resource_path]
				else:
					portrait = character.default_portrait
			Dialogic.current_state_info['rpg_last_portraits'][character.resource_path] = portrait
		var char_joined = false
		for joined_character in dialogic.current_state_info.portraits:
			if not character or (joined_character != character.resource_path):
				var AnimationName = DialogicUtil.get_project_setting('dialogic/animations/leave_default', 
	get_script().resource_path.get_base_dir().path_join('DefaultAnimations/fade_out_down.gd'))
				var AnimationLength = DialogicUtil.get_project_setting('dialogic/animations/leave_default_length', 0.5) 
					
				var anim = animate_portrait(load(joined_character), AnimationName, AnimationLength)
				
				anim.finished.connect(remove_portrait.bind(load(joined_character)))
			else:
				char_joined = true
		
		if (not char_joined) and character and portrait in character.portraits:
			var AnimationName = DialogicUtil.get_project_setting('dialogic/animations/join_default', 
	get_script().resource_path.get_base_dir().path_join('DefaultAnimations/fade_in_up.gd'))
			var AnimationLength = DialogicUtil.get_project_setting('dialogic/animations/join_default_length', 0.5)
			add_portrait(character, portrait, 1, false)
			var anim = animate_portrait(character, AnimationName, AnimationLength)


# makes sure positions are listed and can be accessed
func check_positions_and_holder() -> void:
	if _portrait_holder_reference == null and len(get_tree().get_nodes_in_group('dialogic_portrait_holder')) == 0:
		assert(false, '[Dialogic] If you want to display portraits, you need a PortraitHolder scene!')
	else: 
		if _portrait_holder_reference == null:
			_portrait_holder_reference = get_tree().get_first_node_in_group('dialogic_portrait_holder')
	if _default_positions.size() == 0:
		for node in get_tree().get_nodes_in_group('dialogic_portrait_position'):
			_default_positions[node['position_index']] = node['position']
	
	if current_positions.size() == 0:
		current_positions = _default_positions.duplicate()


func text_effect_portrait(text_node:Control, skipped:bool, argument:String) -> void:
	if argument:
		if Dialogic.current_state_info.get('character', null):
			Dialogic.Portraits.change_portrait(load(Dialogic.current_state_info.character), argument)
