extends DialogicSubsystem

## Subsystem that manages portraits and portrait positions.

## The default portrait scene.
var default_portrait_scene = load(get_script().resource_path.get_base_dir().path_join('default_portrait.tscn'))

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
		printerr('[DialogicError] Cannot call add_portrait() with null character.')
		return null
	if not portrait in character.portraits:
		printerr("[DialogicError] Tried joining ",character.display_name, " with not-existing portrait '", portrait, "'. Will use default portrait instead.")
		portrait = character.default_portrait
		if portrait.is_empty():
			printerr("[DialogicError] Character ",character.display_name, " has no default portrait to use.")
			return null
	
	character_node = Node2D.new()
	character_node.name = character.get_character_name()
	character_node.set_meta('character', character)
	character_node.z_index = z_index
	
	for portrait_position in get_tree().get_nodes_in_group('dialogic_portrait_container'):
		if portrait_position.is_visible_in_tree() and portrait_position.position_index == position_idx:
			portrait_position.add_child(character_node)
			break
	
	if !character_node.is_inside_tree():
		printerr('[Dialogic] Failed to join character to position ', position_idx, ". Could not find position container.")
		remove_portrait(character)
		return
	
	dialogic.current_state_info['portraits'][character.resource_path] = {'portrait':portrait, 'node':character_node, 'position_index':position_idx}
	
	change_portrait(character, portrait)
	change_portrait_mirror(character, mirrored)
	change_portrait_extradata(character, extra_data)
	change_portrait_z_index(character, z_index)
	
	return character_node


## Changes the portrait of a character. Only works with characters that joined previously.
func change_portrait(character:DialogicCharacter, portrait:String, update_transform:=true) -> void:
	if not character or not is_character_joined(character):
		print_debug('[DialogicError] Cannot change portrait of null/not joined character.')
		return
	
	if portrait.is_empty():
		portrait = character.default_portrait
	
	if not portrait in character.portraits.keys():
		print_debug('[Dialogic] Change to not-existing portrait will be ignored!')
		return
	
	var char_node :Node = dialogic.current_state_info.portraits[character.resource_path].node
	
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
	
	dialogic.current_state_info['portraits'][character.resource_path]['portrait'] = portrait
	
	if portrait_node:
		for property in character.portraits[portrait].get('export_overrides', {}).keys():
			portrait_node.set(property, str_to_var(character.portraits[portrait]['export_overrides'][property]))
		
		if portrait_node.has_method('_update_portrait'):
			portrait_node._update_portrait(character, portrait)
		
		if !portrait_node.is_inside_tree():
			char_node.add_child(portrait_node)
		
		if update_transform:
			update_portrait_transform(character)


## Changes the mirroring of the given character. 
## Unless @force is false, this will take into consideration the character mirror, 
## portrait mirror and portrait position mirror settings.
func change_portrait_mirror(character:DialogicCharacter, mirrored:=false, force:=false) -> void:
	var char_node :Node = dialogic.current_state_info.portraits[character.resource_path].node
	if char_node.get_child(0).has_method('_set_mirror'):
		var current_portrait_info := character.get_portrait_info(dialogic.current_state_info.portraits[character.resource_path].portrait)
		char_node.get_child(0)._set_mirror(force or (mirrored != character.mirror != char_node.get_parent().mirrored != current_portrait_info.get('mirror', false)))


func change_portrait_extradata(character:DialogicCharacter, extra_data:="") -> void:
	var char_node :Node = dialogic.current_state_info.portraits[character.resource_path].node
	if char_node.get_child(0).has_method('_set_extra_data'):
		char_node.get_child(0)._set_extra_data(extra_data)


func update_portrait_transform(character:DialogicCharacter, time:float = 0.0) -> void:
	if not character or not is_character_joined(character):
		return
	var char_node :Node2D = dialogic.current_state_info.portraits[character.resource_path].node
	var portrait_node :Node = char_node.get_child(0)
	var portrait_info :Dictionary = character.portraits.get(dialogic.current_state_info['portraits'][character.resource_path]['portrait'], {})
	
	# ignore the character scale on custom portraits that have 'ignore_char_scale' set to true
	var apply_character_scale :bool= portrait_info.get('scene', '') or !portrait_info.get('ignore_char_scale', false)
	var transform :Rect2 = char_node.get_parent().get_local_portrait_transform(
		portrait_node._get_covered_rect(),
		(character.scale * portrait_info.get('scale', 1))*int(apply_character_scale)+portrait_info.get('scale')*int(!apply_character_scale))
	
	var tween : Tween
	if char_node.has_meta('move_tween'):
		if char_node.get_meta('move_tween').is_running():
			time = char_node.get_meta('move_time')-char_node.get_meta('move_tween').get_total_elapsed_time()
			tween = char_node.get_meta('move_tween')
	if time == 0:
		char_node.position = transform.position
		portrait_node.position = character.offset + portrait_info.get('offset', Vector2())
		portrait_node.scale = transform.size
	else:
		if !tween:
			tween = char_node.create_tween().set_parallel().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			char_node.set_meta('move_tween', tween)
			char_node.set_meta('move_time', time)
		tween.tween_property(char_node, 'position', transform.position, time)
		tween.tween_property(portrait_node, 'position',character.offset + portrait_info.get('offset', Vector2()), time)
		tween.tween_property(portrait_node, 'scale', transform.size, time)


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
func move_portrait(character:DialogicCharacter, position_idx:int, time:float = 0.0) -> void:
	if not character or not is_character_joined(character):
		print_debug('[DialogicError] Cannot move portrait of null/not joined character.')
		return
	
	var char_node :Node2D= dialogic.current_state_info.portraits[character.resource_path].node
	
	var global_pos := char_node.global_position
	if char_node.get_parent(): char_node.get_parent().remove_child(char_node)
	
	for portrait_position in get_tree().get_nodes_in_group('dialogic_portrait_container'):
		if portrait_position.is_visible_in_tree() and portrait_position.position_index == position_idx:
			portrait_position.add_child(char_node)
			break
	
	if !char_node.is_inside_tree():
		printerr('[Dialogic] Failed to move character to position ', position_idx, ". Could not find position container.")
		remove_portrait(character)
		return
	
	
	char_node.position = global_pos-char_node.get_parent().global_position
	update_portrait_transform(character, time)
	
	dialogic.current_state_info.portraits[character.resource_path].position_index = position_idx


func change_portrait_z_index(character:DialogicCharacter, z_index:int, update_zindex:= true) -> void:
	var char_node :Node2D= dialogic.current_state_info.portraits[character.resource_path].node
	if update_zindex:
		char_node.z_index = z_index


func remove_portrait(character:DialogicCharacter) -> void:
	dialogic.current_state_info['portraits'][character.resource_path].node.queue_free()
	dialogic.current_state_info['portraits'].erase(character.resource_path)


## Creates a new portrait container node. 
## It will copy it's size and most settings from the first p_container in the tree. 
## It will be added as a sibling of the first p_container in the tree.
func add_portrait_position(position_index: int, position:Vector2) -> void:
	var example_position := get_tree().get_first_node_in_group('dialogic_portrait_container')
	if example_position:
		var new_position := DialogicNode_PortraitContainer.new() 
		example_position.get_parent().add_child(new_position)
		new_position.size = example_position.size
		new_position.size_mode = example_position.size_mode
		new_position.origin_anchor = example_position.origin_anchor
		new_position.position_index = position_index
		new_position.position = position-new_position._get_origin_position()


func move_portrait_position(position_index: int, vector:Vector2, relative:bool = false, time:float = 0.0) -> void:
	for portrait_position in get_tree().get_nodes_in_group('dialogic_portrait_container'):
		if portrait_position.is_visible_in_tree() and portrait_position.position_index == position_index:
			if !portrait_position.has_meta('default_position'):
				portrait_position.set_meta('default_position', portrait_position.position)
			var tween := portrait_position.create_tween()
			if !relative:
				tween.tween_property(portrait_position, 'position', vector, time)
			else:
				tween.tween_property(portrait_position, 'position', vector, time).as_relative()
			return
	
	# If this is reached, no position could be found. If the position is absolute, we will add it.
	if !relative:
		add_portrait_position(position_index, vector)


func reset_portrait_positions(time:float = 0.0) -> void:
	for portrait_position in get_tree().get_nodes_in_group('dialogic_portrait_container'):
		if portrait_position.is_visible_in_tree():
			if portrait_position.has_meta('default_position'):
				move_portrait_position(portrait_position.position_index, portrait_position.get_meta('default_position'), false, time)


func reset_portrait_position(position_index:int, time:float = 0.0) -> void:
	for portrait_position in get_tree().get_nodes_in_group('dialogic_portrait_container'):
		if portrait_position.is_visible_in_tree() and portrait_position.position_index == position_index:
			if portrait_position.has_meta('default_position'):
				move_portrait_position(position_index, portrait_position.get_meta('default_position'), false, time)


####################################################################################################
##					TEXT EFFECTS
####################################################################################################

func text_effect_portrait(text_node:Control, skipped:bool, argument:String) -> void:
	if argument:
		if Dialogic.current_state_info.get('character', null):
			Dialogic.Portraits.change_portrait(load(Dialogic.current_state_info.character), argument)


####################################################################################################
##					HELPERS
####################################################################################################

func is_character_joined(character:DialogicCharacter) -> bool:
	return character.resource_path in dialogic.current_state_info['portraits']


func get_joined_characters() -> Array[DialogicCharacter]:
	var chars :Array[DialogicCharacter]= []
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
		var char_joined := false
		for joined_character in dialogic.current_state_info.portraits:
			if not character or (joined_character != character.resource_path):
				var AnimationName :String= DialogicUtil.get_project_setting('dialogic/animations/leave_default', 
	get_script().resource_path.get_base_dir().path_join('DefaultAnimations/fade_out_down.gd'))
				var AnimationLength :float= DialogicUtil.get_project_setting('dialogic/animations/leave_default_length', 0.5) 
					
				var anim := animate_portrait(load(joined_character), AnimationName, AnimationLength)
				
				anim.finished.connect(remove_portrait.bind(load(joined_character)))
			else:
				char_joined = true
		
		if (not char_joined) and character and portrait in character.portraits:
			var AnimationName :String= DialogicUtil.get_project_setting('dialogic/animations/join_default', 
	get_script().resource_path.get_base_dir().path_join('DefaultAnimations/fade_in_up.gd'))
			var AnimationLength :float= DialogicUtil.get_project_setting('dialogic/animations/join_default_length', 0.5)
			add_portrait(character, portrait, 1, false)
			var anim := animate_portrait(character, AnimationName, AnimationLength)
