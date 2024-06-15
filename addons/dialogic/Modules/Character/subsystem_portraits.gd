extends DialogicSubsystem

## Subsystem that manages portraits and portrait positions.

signal character_joined(info:Dictionary)
signal character_left(info:Dictionary)
signal character_portrait_changed(info:Dictionary)
signal character_moved(info:Dictionary)
signal position_changed(info:Dictionary)

## Emitted when a portrait starts animating.
signal portrait_animating(character_node: Node, portrait_node: Node, animation_name: String, animation_length: float)


## The default portrait scene.
var default_portrait_scene: PackedScene = load(get_script().resource_path.get_base_dir().path_join('default_portrait.tscn'))


#region STATE
####################################################################################################

func clear_game_state(_clear_flag:=DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	for character in dialogic.current_state_info.get('portraits', {}).keys():
		remove_character(load(character))
	dialogic.current_state_info['portraits'] = {}


func load_game_state(_load_flag:=LoadFlags.FULL_LOAD) -> void:
	if not "portraits" in dialogic.current_state_info:
		dialogic.current_state_info["portraits"] = {}

	var portraits_info: Dictionary = dialogic.current_state_info.portraits.duplicate()
	dialogic.current_state_info.portraits = {}
	for character_path in portraits_info:
		var character_info: Dictionary = portraits_info[character_path]
		await join_character(load(character_path), character_info.portrait,
						character_info.position_index,
						character_info.get('custom_mirror', false),
						character_info.get('z_index', 0),
						character_info.get('extra_data', ""),
						"InstantInOrOut", 0, false)
	var speaker: Variant = dialogic.current_state_info.get('speaker', "")
	if speaker:
		dialogic.current_state_info['speaker'] = ""
		change_speaker(load(speaker))
	dialogic.current_state_info['speaker'] = speaker


func pause() -> void:
	for portrait in dialogic.current_state_info['portraits'].values():
		if portrait.node.has_meta('animation_node'):
			portrait.node.get_meta('animation_node').pause()


func resume() -> void:
	for portrait in dialogic.current_state_info['portraits'].values():
		if portrait.node.has_meta('animation_node'):
			portrait.node.get_meta('animation_node').resume()


func _ready() -> void:
	if !ProjectSettings.get_setting('dialogic/portraits/default_portrait', '').is_empty():
		default_portrait_scene = load(ProjectSettings.get_setting('dialogic/portraits/default_portrait', ''))

	portrait_animating.connect(_on_portrait_animating)


func _on_portrait_animating(character_node: Node, _portrait_node: Node, animation_name: String, animation_length: float) -> void:
	var child_count := character_node.get_child_count()

	# Start removal of the current portrait.
	if child_count > 1:
		# We always delete the previous portrait node.
		var previous_portrait_index := child_count - 2
		var previous_portrait_node := character_node.get_child(previous_portrait_index)
		previous_portrait_node.z_index = 2
		_remove_portrait_timed(previous_portrait_node, animation_name, animation_length)

#endregion


#region MAIN METHODS
####################################################################################################
## The following methods allow manipulating portraits.
## A portrait is made up of a character node [Node2D] that instances the portrait scene as it's child.
## The character node is then always the child of a portrait container.
## - Position (PortraitContainer)
## ---- character_node (Node2D)
## --------- portrait_node (e.g. default_portrait.tscn, or a custom portrait)
##
## Using these main methods a character can be present multiple times.
## For a VN style, the "character" methods (next section) provide access based on the character.
## - (That is what the character event uses)

## Creates a new [character node] for the given [character], and add it to the given [portrait container].
func _create_character_node(character:DialogicCharacter, container:DialogicNode_PortraitContainer) -> Node:
	var character_node := Node2D.new()
	character_node.name = character.get_character_name()
	character_node.set_meta('character', character)
	container.add_child(character_node)
	return character_node


## Instead of instantly freeing the portrait scene, we will play an animation
## and then free it.
## This allows for cross-fade effects and other animations.
##
## If [param duration_seconds] is `0.0`, the portrait will be removed instantly.
func _remove_portrait_timed(portrait_node: Node, animation_path := "Fade In Out", duration_seconds := 0.0) -> void:

	if duration_seconds > 0:
		# TODO: Allow setting the animation
		var animation_name := DialogicResourceUtil.guess_special_resource("PortraitAnimation", animation_path, "")
		var animation := _animate_portrait(portrait_node, animation_name, duration_seconds, 0, true, true)
		await animation.finished

	portrait_node.queue_free()


# Changes the portrait of a specific [character node].
func _change_portrait(character_node: Node2D, portrait: String, update_transform := true) -> Dictionary:
	var character: DialogicCharacter = character_node.get_meta('character')

	if portrait.is_empty():
		portrait = character.default_portrait

	var info := {'character':character, 'portrait':portrait, 'same_scene':false}

	if not portrait in character.portraits.keys():
		print_debug('[Dialogic] Change to not-existing portrait will be ignored!')
		return info

	# Path to the scene to use.
	var scene_path: String = character.portraits[portrait].get('scene', '')

	var portrait_node: Node = null
	var latest_portrait: Node = null
	var portrait_count := character_node.get_child_count()

	if portrait_count > 0:
		latest_portrait = character_node.get_child(-1)

	# Check if the scene is the same as the currently loaded scene.
	if (not latest_portrait == null and
		latest_portrait.get_meta('scene', '') == scene_path and
		# Also check if the scene supports changing to the given portrait.
		latest_portrait._should_do_portrait_update(character, portrait)):
			portrait_node = latest_portrait
			info['same_scene'] = true

	else:

		if ResourceLoader.exists(scene_path):
			var packed_scene: PackedScene = load(scene_path)

			if packed_scene:
				portrait_node = packed_scene.instantiate()
			else:
				push_error('[Dialogic] Portrait node "' + str(scene_path) + '" for character [' + character.display_name + '] could not be loaded. Your portrait might not show up on the screen. Confirm the path is correct.')

		if !portrait_node:
			portrait_node = default_portrait_scene.instantiate()

		portrait_node.set_meta('scene', scene_path)


	if portrait_node:
		character_node.set_meta('portrait', portrait)

		DialogicUtil.apply_scene_export_overrides(portrait_node, character.portraits[portrait].get('export_overrides', {}))

		if portrait_node.has_method('_update_portrait'):
			portrait_node._update_portrait(character, portrait)

		if not portrait_node.is_inside_tree():

			if portrait_count > 1:
				_remove_portrait(character_node.get_child(0))

			character_node.add_child(portrait_node)

		if update_transform:
			_update_portrait_transform(portrait_node)

	return info


## Changes the mirroring of the given portrait.
## Unless @force is false, this will take into consideration the character mirror,
## portrait mirror and portrait position mirror settings.
func _change_portrait_mirror(character_node: Node2D, mirrored := false, force := false) -> void:
	var latest_portrait := character_node.get_child(-1)

	if latest_portrait.has_method('_set_mirror'):
		var character: DialogicCharacter = character_node.get_meta('character')
		var current_portrait_info := character.get_portrait_info(character_node.get_meta('portrait'))
		latest_portrait._set_mirror(force or (mirrored != character.mirror != character_node.get_parent().mirrored != current_portrait_info.get('mirror', false)))


func _change_portrait_extradata(character_node: Node2D, extra_data := "") -> void:
	var latest_portrait := character_node.get_child(-1)

	if latest_portrait.has_method('_set_extra_data'):
		latest_portrait._set_extra_data(extra_data)


func _update_portrait_transform(portrait_node: Node, time:float = 0.0) -> void:
	var character_node: Node = portrait_node.get_parent()

	var character: DialogicCharacter = character_node.get_meta('character')
	var portrait_info: Dictionary = character.portraits.get(character_node.get_meta('portrait'), {})

	# ignore the character scale on custom portraits that have 'ignore_char_scale' set to true
	var apply_character_scale: bool= !portrait_info.get('ignore_char_scale', false)
	var transform: Rect2 = character_node.get_parent().get_local_portrait_transform(
		portrait_node._get_covered_rect(),
		(character.scale * portrait_info.get('scale', 1))*int(apply_character_scale)+portrait_info.get('scale', 1)*int(!apply_character_scale))

	var tween: Tween

	if character_node.has_meta('move_tween'):

		if character_node.get_meta('move_tween').is_running():
			time = character_node.get_meta('move_time')-character_node.get_meta('move_tween').get_total_elapsed_time()
			tween = character_node.get_meta('move_tween')

	if time == 0:
		character_node.position = transform.position
		portrait_node.position = character.offset + portrait_info.get('offset', Vector2())
		portrait_node.scale = transform.size
	else:

		if !tween:
			tween = character_node.create_tween().set_parallel().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			character_node.set_meta('move_tween', tween)
			character_node.set_meta('move_time', time)

		tween.tween_property(character_node, 'position', transform.position, time)
		tween.tween_property(portrait_node, 'position',character.offset + portrait_info.get('offset', Vector2()), time)
		tween.tween_property(portrait_node, 'scale', transform.size, time)


## Animates the portrait in the given container with the given animation.
func _animate_portrait(portrait_node: Node, animation_path: String, length: float, repeats := 1, is_reversed := false, is_silent := false) -> DialogicAnimation:

	if portrait_node.has_meta('animation_node') and is_instance_valid(portrait_node.get_meta('animation_node')):
		portrait_node.get_meta('animation_node').queue_free()

	var anim_script: Script = load(animation_path)
	var anim_node := Node.new()
	anim_node.set_script(anim_script)
	anim_node = (anim_node as DialogicAnimation)
	anim_node.node = portrait_node
	anim_node.orig_pos = portrait_node.position
	anim_node.end_position = portrait_node.position
	anim_node.time = length
	anim_node.repeats = repeats
	anim_node.is_reversed = is_reversed

	add_child(anim_node)
	anim_node.animate()

	portrait_node.set_meta("animation_path", animation_path)
	portrait_node.set_meta("animation_length", length)
	portrait_node.set_meta("animation_node", anim_node)

	if not is_silent:
		portrait_animating.emit(portrait_node.get_parent(), portrait_node, animation_path, length)

	return anim_node


## Moves the given portrait to the given container.
func _move_portrait(portrait_node: Node2D, portrait_container: DialogicNode_PortraitContainer, time := 0.0) -> void:
	var global_pos := portrait_node.global_position

	if portrait_node.get_parent():
		portrait_node.get_parent().remove_child(portrait_node)

	portrait_container.add_child(portrait_node)

	portrait_node.position = global_pos - portrait_node.get_parent().global_position

	_update_portrait_transform(portrait_node.get_child(-1), time)


## Changes the given portraits z_index.
func _change_portrait_z_index(character_node: Node, z_index:int, update_zindex:= true) -> void:
	if update_zindex:
		character_node.get_parent().set_meta('z_index', z_index)

		var sorted_children := character_node.get_parent().get_parent().get_children()
		sorted_children.sort_custom(z_sort_portrait_containers)
		var idx := 0
		for con in sorted_children:
			con.get_parent().move_child(con, idx)
			idx += 1


## Checks if [para, character] has joined the scene, if so, returns its
## active [DialogicPortrait] node.
##
## The difference between an active and inactive nodes is whether the node is
## the latest node. [br]
## If a portrait is fading/animating from portrait A and B, both will exist
## in the scene, but only the new portrait is active, even if it is not
## fully visible yet.
func get_character_portrait(character: DialogicCharacter) -> DialogicPortrait:
	if is_character_joined(character):
		var portrait_node: DialogicPortrait = dialogic.current_state_info['portraits'][character.resource_path].node.get_child(-1)
		return portrait_node

	return null


func z_sort_portrait_containers(con1: DialogicNode_PortraitContainer, con2: DialogicNode_PortraitContainer) -> bool:
	if con1.get_meta('z_index', 0) < con2.get_meta('z_index', 0):
		return true

	return false


## Private method to remove a [param portrait_node].
func _remove_portrait(portrait_node: Node) -> void:
	_remove_portrait_timed(portrait_node)


## Gets the default animation length for joining characters
## If Auto-Skip is enabled, limits the time.
func _get_join_default_length() -> float:
	var default_time: float = ProjectSettings.get_setting('dialogic/animations/join_default_length', 0.5)

	if dialogic.Inputs.auto_skip.enabled:
		default_time = min(default_time, dialogic.Inputs.auto_skip.time_per_event)

	return default_time


## Gets the default animation length for leaving characters
## If Auto-Skip is enabled, limits the time.
func _get_leave_default_length() -> float:
	var default_time: float = ProjectSettings.get_setting('dialogic/animations/leave_default_length', 0.5)

	if dialogic.Inputs.auto_skip.enabled:
		default_time = min(default_time, dialogic.Inputs.auto_skip.time_per_event)

	return default_time


## Checks multiple cases to return a valid portrait to use.
func get_valid_portrait(character:DialogicCharacter, portrait:String) -> String:
	if character == null:
		printerr('[Dialogic] Tried to use portrait "', portrait, '" on <null> character.')
		dialogic.print_debug_moment()
		return ""

	if "{" in portrait and dialogic.has_subsystem("Expressions"):
		var test: Variant = dialogic.Expressions.execute_string(portrait)
		if test:
			portrait = str(test)

	if not portrait in character.portraits:
		if not portrait.is_empty():
			printerr('[Dialogic] Tried to use invalid portrait "', portrait, '" on character "', DialogicResourceUtil.get_unique_identifier(character.resource_path), '". Using default portrait instead.')
			dialogic.print_debug_moment()
		portrait = character.default_portrait

	if portrait.is_empty():
		portrait = character.default_portrait

	return portrait

#endregion


#region Character Methods
####################################################################################################
## The following methods are used to manage character portraits with the following rules:
##   - a character can only be present once with these methods.
## Most of them will fail silently if the character isn't joined yet.


## Adds a character at a position and sets it's portrait.
## If the character is already joined it will only update, portrait, position, etc.
func join_character(character:DialogicCharacter, portrait:String,  position_idx:int, mirrored:= false, z_index:= 0, extra_data:= "", animation_name:= "", animation_length:= 0.0, animation_wait := false) -> Node:

	if is_character_joined(character):
		change_character_portrait(character, portrait)

		if animation_name.is_empty():
			animation_length = _get_join_default_length()

		if animation_wait:
			dialogic.current_state = DialogicGameHandler.States.ANIMATING
			await get_tree().create_timer(animation_length).timeout
			dialogic.current_state = DialogicGameHandler.States.IDLE

		move_character(character, position_idx, animation_length)
		change_character_mirror(character, mirrored)

		return

	var character_node := add_character(character, portrait, position_idx)

	if character_node == null:
		return null

	dialogic.current_state_info['portraits'][character.resource_path] = {'portrait':portrait, 'node':character_node, 'position_index':position_idx, 'custom_mirror':mirrored}

	_change_portrait_mirror(character_node, mirrored)
	_change_portrait_extradata(character_node, extra_data)
	_change_portrait_z_index(character_node, z_index)

	var info := {'character':character}
	info.merge(dialogic.current_state_info['portraits'][character.resource_path])
	character_joined.emit(info)

	if animation_name.is_empty():
		animation_name = ProjectSettings.get_setting('dialogic/animations/join_default', "Fade Up In")
		animation_length = _get_join_default_length()
		animation_wait = ProjectSettings.get_setting('dialogic/animations/join_default_wait', true)

	animation_name = DialogicResourceUtil.guess_special_resource("PortraitAnimation", animation_name, "")

	if animation_name and animation_length > 0:
		var anim: DialogicAnimation = _animate_portrait(character_node.get_child(-1), animation_name, animation_length)

		if animation_wait:
			dialogic.current_state = DialogicGameHandler.States.ANIMATING
			await anim.finished
			dialogic.current_state = DialogicGameHandler.States.IDLE

	return character_node


func add_character(character:DialogicCharacter, portrait:String,  position_idx:int) -> Node:
	if is_character_joined(character):
		printerr('[DialogicError] Cannot add a already joined character. If this is intended call _create_character_node manually.')
		return null

	portrait = get_valid_portrait(character, portrait)

	if portrait.is_empty():
		return null

	if not character:
		printerr('[DialogicError] Cannot call add_portrait() with null character.')
		return null

	var character_node: Node = null

	for portrait_position in get_tree().get_nodes_in_group('dialogic_portrait_con_position'):
		if portrait_position.is_visible_in_tree() and portrait_position.position_index == position_idx:
			character_node = _create_character_node(character, portrait_position)
			break

	if character_node == null:
		printerr('[Dialogic] Failed to join character to position ', position_idx, ". Could not find position container.")
		return null

	dialogic.current_state_info['portraits'][character.resource_path] = {'portrait':portrait, 'node':character_node, 'position_index':position_idx}

	_change_portrait(character_node, portrait)

	return character_node


## Changes the portrait of a character. Only works with joined characters.
func change_character_portrait(character: DialogicCharacter, portrait: String, update_transform := true) -> void:
	if !is_character_joined(character):
		return

	portrait = get_valid_portrait(character, portrait)

	if dialogic.current_state_info.portraits[character.resource_path].portrait == portrait:
		return

	var info := _change_portrait(dialogic.current_state_info.portraits[character.resource_path].node, portrait, update_transform)
	dialogic.current_state_info.portraits[character.resource_path].portrait = info.portrait
	_change_portrait_mirror(
			dialogic.current_state_info.portraits[character.resource_path].node,
			dialogic.current_state_info.portraits[character.resource_path].get('custom_mirror', false)
			)
	character_portrait_changed.emit(info)


## Changes the mirror of the given character. Only works with joined characters
func change_character_mirror(character:DialogicCharacter, mirrored:= false, force:= false) -> void:
	if !is_character_joined(character):
		return

	_change_portrait_mirror(dialogic.current_state_info.portraits[character.resource_path].node, mirrored, force)
	dialogic.current_state_info.portraits[character.resource_path]['custom_mirror'] = mirrored


## Changes the z_index of a character. Only works with joined characters
func change_character_z_index(character:DialogicCharacter, z_index:int, update_zindex:= true) -> void:
	if !is_character_joined(character):
		return

	_change_portrait_z_index(dialogic.current_state_info.portraits[character.resource_path].node, z_index, update_zindex)
	if update_zindex:
		dialogic.current_state_info.portraits[character.resource_path]['z_index'] = z_index


## Changes the extra data on the given character. Only works with joined characters
func change_character_extradata(character:DialogicCharacter, extra_data:="") -> void:
	if !is_character_joined(character):
		return
	_change_portrait_extradata(dialogic.current_state_info.portraits[character.resource_path].node, extra_data)
	dialogic.current_state_info.portraits[character.resource_path]['extra_data'] = extra_data


## Starts the given animation on the given character. Only works with joined characters
func animate_character(character: DialogicCharacter, animation_path: String, length: float, repeats := 1, is_reversed := false) -> DialogicAnimation:
	if not is_character_joined(character):
		return null

	animation_path = DialogicResourceUtil.guess_special_resource("PortraitAnimation", animation_path, "")

	var character_node: Node = dialogic.current_state_info.portraits[character.resource_path].node
	var portrait_node: Node = character_node.get_child(-1)

	return _animate_portrait(portrait_node, animation_path, length, repeats, is_reversed)


## Moves the given character to the given position. Only works with joined characters
func move_character(character: DialogicCharacter, position_idx: int, time := 0.0) -> void:
	if !is_character_joined(character):
		return

	if dialogic.current_state_info.portraits[character.resource_path].position_index == position_idx:
		return

	var containers: Array[Node] = get_tree().get_nodes_in_group('dialogic_portrait_con_position')

	for portrait_position: DialogicNode_PortraitContainer in containers:

		if portrait_position.is_visible_in_tree() and portrait_position.position_index == position_idx:
			var character_node: Node2D = dialogic.current_state_info.portraits[character.resource_path].node

			_move_portrait(character_node, portrait_position, time)
			dialogic.current_state_info.portraits[character.resource_path].position_index = position_idx
			character_moved.emit({'character':character, 'position_index':position_idx, 'time':time})
			return

	printerr('[Dialogic] Unable to move character to position ', position_idx, ". Couldn't find position container.")


## Removes a character with a given animation or the default animation.
func leave_character(character: DialogicCharacter, animation_name:= "", animation_length:= 0.0, animation_wait := false) -> void:
	if not is_character_joined(character):
		return

	if animation_name.is_empty():
		animation_name = ProjectSettings.get_setting('dialogic/animations/leave_default', "Fade Down Out")
		animation_length = _get_leave_default_length()
		animation_wait = ProjectSettings.get_setting('dialogic/animations/leave_default_wait', true)

	animation_name = DialogicResourceUtil.guess_special_resource("PortraitAnimation", animation_name, "")

	if not animation_name.is_empty():
		var character_node := get_character_node(character)
		var last_portrait := character_node.get_child(-1)

		if animation_wait:
			dialogic.current_state = DialogicGameHandler.States.ANIMATING
			await _remove_portrait_timed(last_portrait, animation_name, animation_length)
			dialogic.current_state = DialogicGameHandler.States.IDLE

		else:
			await _remove_portrait_timed(last_portrait, animation_name, animation_length)

	remove_character(character)


## Removes all joined characters with a given animation or the default animation.
func leave_all_characters(animation_name:="", animation_length:=0.0, animation_wait := false) -> void:
	for character in get_joined_characters():
		await leave_character(character, animation_name, animation_length, animation_wait)

	if animation_name.is_empty():
		animation_length = _get_leave_default_length()
		animation_wait = ProjectSettings.get_setting('dialogic/animations/leave_default_wait', true)


## Finds the character node for a [param character].
## Return `null` if the [param character] is not part of the scene.
func get_character_node(character: DialogicCharacter) -> Node:
	if is_character_joined(character):
		return dialogic.current_state_info['portraits'][character.resource_path].node

	return null


## Removes the given characters portrait.
## Only works with joined characters.
func remove_character(character: DialogicCharacter) -> void:
	var character_node := get_character_node(character)

	if is_instance_valid(character_node) and character_node is Node:
		character_node.queue_free()
		character_left.emit({'character': character})

	dialogic.current_state_info['portraits'].erase(character.resource_path)


func get_current_character() -> DialogicCharacter:
	if dialogic.current_state_info.get('speaker', null):
		return load(dialogic.current_state_info.speaker)
	return null



## Returns true if the given character is currently joined.
func is_character_joined(character: DialogicCharacter) -> bool:
	if character == null or not character.resource_path in dialogic.current_state_info['portraits']:
		return false

	return true


## Returns a list of the joined charcters (as resources)
func get_joined_characters() -> Array[DialogicCharacter]:
	var chars: Array[DialogicCharacter] = []

	for char_path: String in dialogic.current_state_info.get('portraits', {}).keys():
		chars.append(load(char_path))

	return chars


## Returns a dictionary with info on a given character.
## Keys can be [joined, character, node (for the portrait node), position_index]
## Only joined is included (and false) for not joined characters
func get_character_info(character:DialogicCharacter) -> Dictionary:
	if is_character_joined(character):
		var info: Dictionary = dialogic.current_state_info['portraits'][character.resource_path]
		info['joined'] = true
		return info
	else:
		return {'joined':false}

#endregion


#region Positions
####################################################################################################

func get_portrait_container(postion_index:int) -> DialogicNode_PortraitContainer:
	for portrait_position in get_tree().get_nodes_in_group('dialogic_portrait_con_position'):
		if portrait_position.is_visible_in_tree() and portrait_position.position_index == postion_index:
			return portrait_position
	return null


## Creates a new portrait container node.
## It will copy it's size and most settings from the first p_container in the tree.
## It will be added as a sibling of the first p_container in the tree.
func add_portrait_position(position_index: int, position:Vector2) -> void:
	var example_position := get_tree().get_first_node_in_group('dialogic_portrait_con_position')
	if example_position:
		var new_position := DialogicNode_PortraitContainer.new()
		example_position.get_parent().add_child(new_position)
		new_position.size = example_position.size
		new_position.size_mode = example_position.size_mode
		new_position.origin_anchor = example_position.origin_anchor
		new_position.position_index = position_index
		new_position.position = position-new_position._get_origin_position()
		position_changed.emit({'change':'added', 'container_node':new_position, 'position_index':position_index})


func move_portrait_position(position_index: int, vector:Vector2, relative:= false, time:= 0.0) -> void:
	for portrait_container in get_tree().get_nodes_in_group('dialogic_portrait_con_position'):
		if portrait_container.is_visible_in_tree() and portrait_container.position_index == position_index:
			if !portrait_container.has_meta('default_position'):
				portrait_container.set_meta('default_position', portrait_container.position)
			var tween := portrait_container.create_tween()
			if !relative:
				tween.tween_property(portrait_container, 'position', vector, time)
			else:
				tween.tween_property(portrait_container, 'position', vector, time).as_relative()
			position_changed.emit({'change':'moved', 'container_node':portrait_container, 'position_index':position_index})
			return

	# If this is reached, no position could be found. If the position is absolute, we will add it.
	if !relative:
		add_portrait_position(position_index, vector)


func reset_all_portrait_positions(time:= 0.0) -> void:
	for portrait_position in get_tree().get_nodes_in_group('dialogic_portrait_con_position'):
		if portrait_position.is_visible_in_tree():
			if portrait_position.has_meta('default_position'):
				move_portrait_position(portrait_position.position_index, portrait_position.get_meta('default_position'), false, time)


func reset_portrait_position(position_index:int, time:= 0.0) -> void:
	for portrait_position in get_tree().get_nodes_in_group('dialogic_portrait_con_position'):
		if portrait_position.is_visible_in_tree() and portrait_position.position_index == position_index:
			if portrait_position.has_meta('default_position'):
				move_portrait_position(position_index, portrait_position.get_meta('default_position'), false, time)

#endregion


#region SPEAKER PORTRAIT CONTAINERS
####################################################################################################

## Updates all portrait containers set to SPEAKER.
func change_speaker(speaker: DialogicCharacter = null, portrait := "") -> void:
	for container: Node in get_tree().get_nodes_in_group('dialogic_portrait_con_speaker'):

		for character_node: Node in container.get_children():

			if not character_node.get_meta('character') == speaker:

				for portrait_node: Node in character_node.get_children():
					_remove_portrait(portrait_node)

		if speaker == null or speaker.portraits.is_empty():
			continue

		if container.get_children().is_empty():
			_create_character_node(speaker, container)
		elif portrait.is_empty():
			continue

		if portrait.is_empty(): portrait = speaker.default_portrait

		if container.portrait_prefix+portrait in speaker.portraits:
			_change_portrait(container.get_child(-1), container.portrait_prefix+portrait)
		else:
			_change_portrait(container.get_child(-1), portrait)

		# if the character has no portraits _change_portrait won't actually add a child node
		if container.get_child(-1).get_child_count() == 0:
			continue

		_change_portrait_mirror(container.get_child(-1))

	if speaker:

		if speaker.resource_path != dialogic.current_state_info['speaker']:

			if dialogic.current_state_info['speaker'] and is_character_joined(load(dialogic.current_state_info['speaker'])):
				dialogic.current_state_info['portraits'][dialogic.current_state_info['speaker']].node.get_child(-1)._unhighlight()

			if speaker and is_character_joined(speaker):
				dialogic.current_state_info['portraits'][speaker.resource_path].node.get_child(-1)._highlight()

	elif dialogic.current_state_info['speaker'] and is_character_joined(load(dialogic.current_state_info['speaker'])):
		dialogic.current_state_info['portraits'][dialogic.current_state_info['speaker']].node.get_child(-1)._unhighlight()

#endregion


#region TEXT EFFECTS
####################################################################################################

## Called from the [portrait=something] text effect.
func text_effect_portrait(_text_node:Control, _skipped:bool, argument:String) -> void:
	if argument:
		if dialogic.current_state_info.get('speaker', null):
			change_character_portrait(load(dialogic.current_state_info.speaker), argument)
			change_speaker(load(dialogic.current_state_info.speaker), argument)
#endregion
