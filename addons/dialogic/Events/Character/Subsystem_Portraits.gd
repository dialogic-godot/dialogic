extends DialogicSubsystem

var default_portrait_scene

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

func _ready():
	default_portrait_scene = load("res://addons/dialogic/Other/DefaultPortrait.tscn")

####################################################################################################
##					MAIN METHODS
####################################################################################################

func add_portrait(character:DialogicCharacter, portrait:String,  position_idx:int, mirrored: bool = false) -> Node:
	var character_node = null
	
	if portrait.is_empty():
		portrait = character.default_portrait
	
	if not character:
		assert(false, "[Dialogic] Cannot add portrait of null character.")
	if not portrait in character.portraits:
		print("[DialogicErrorInfo] ",character.display_name, " has no portrait ", portrait)
		assert(false, "[Dialogic] Invalid portrait name.")
	if len(get_tree().get_nodes_in_group('dialogic_portrait_holder')) == 0:
		assert(false, '[Dialogic] If you want to display portraits, you need a PortraitHolder scene!')
	
	for node in get_tree().get_nodes_in_group('dialogic_portrait_position'):
		if node.position_index == position_idx:
			character_node = Node2D.new()
			character_node.name = character.name
			node.add_child(character_node)
			character_node.global_position = node.global_position
	if character_node:
		dialogic.current_state_info['portraits'][character.resource_path] = {'portrait':portrait, 'node':character_node, 'position_index':position_idx}
	if portrait:
		change_portrait(character, portrait,mirrored)
	
	return character_node

func change_portrait(character:DialogicCharacter, portrait:String, mirrored:bool = false) -> void:
	if not character or not is_character_joined(character):
		assert(false, "[Dialogic] Cannot change portrait of null/not joined character.")
	
	if portrait.is_empty():
		portrait = character.default_portrait
	
	var char_node :Node = dialogic.current_state_info.portraits[character.resource_path].node
	
	if char_node.get_child_count() and 'does_custom_portrait_change' in char_node.get_child(0) and char_node.get_child(0).does_portrait_change():
		char_node.get_child(0).change_portrait(character, portrait)
	else:
		# remove previous portrait
		if char_node.get_child_count():
			char_node.get_child(0).queue_free()
		
		var path = character.portraits[portrait].path
		if not path.ends_with('.tscn'):
			var sprite = default_portrait_scene.instantiate()
			sprite.change_portrait(character, portrait)
			sprite.position.x -= sprite.portrait_width/2.0
			sprite.position.y -= sprite.portrait_height
			
			if sprite.does_portrait_mirror():
				sprite.mirror_portrait(mirrored)
			
			char_node.add_child(sprite)
		else:
			var sprite = load(path)
			sprite.position.x -= sprite.portrait_width/2.0
			sprite.position.y -= sprite.portrait_height
			if sprite.does_portrait_mirror():
				sprite.mirror_portrait(mirrored)
			char_node.add_child(path)
	dialogic.current_state_info['portraits'][character.resource_path]['portrait'] = portrait


func animate_portrait(character:DialogicCharacter, animation_path:String, length:float, repeats = 1) -> DialogicAnimation:
	if not character or not is_character_joined(character):
		assert(false, "[Dialogic] Cannot animate portrait of null/not joined character.")
	
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

func move_portrait(character:DialogicCharacter, position_idx:int, tween:bool= false, time:float = 1.0):
	if not character or not is_character_joined(character):
		assert(false, "[Dialogic] Cannot move portrait of null/not joined character.")
	
	var char_node = dialogic.current_state_info.portraits[character.resource_path].node
	
	for node in get_tree().get_nodes_in_group('dialogic_portrait_position'):
		if node.position_index == position_idx:
			if not tween:
				char_node.global_position = node.global_position
	
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

func update_rpg_portrait_mode(character:DialogicCharacter = null, portrait:String = "") -> void:
	if DialogicUtil.get_project_setting('dialogic/portrait_mode', 0) == DialogicCharacterEvent.PortraitModes.RPG:
		var char_joined = false
		for joined_character in dialogic.current_state_info.portraits:
			if not character or (joined_character != character.resource_path):
				var AnimationName = DialogicUtil.get_project_setting('dialogic/animations/leave_default', 
	get_script().resource_path.get_base_dir().plus_file('DefaultAnimations/fade_out_down.gd'))
				var AnimationLength = DialogicUtil.get_project_setting('dialogic/animations/leave_default_length', 0.5) 
					
				var anim = animate_portrait(load(joined_character), AnimationName, AnimationLength)
				
				anim.finished.connect(remove_portrait.bind(load(joined_character)))
			else:
				char_joined = true
		
		if (not char_joined) and character and portrait in character.portraits:
			var AnimationName = DialogicUtil.get_project_setting('dialogic/animations/join_default', 
	get_script().resource_path.get_base_dir().plus_file('DefaultAnimations/fade_in_up.gd'))
			var AnimationLength = DialogicUtil.get_project_setting('dialogic/animations/join_default_length', 0.5)
			add_portrait(character, portrait, 0, false)
			var anim = animate_portrait(character, AnimationName, AnimationLength)
			
