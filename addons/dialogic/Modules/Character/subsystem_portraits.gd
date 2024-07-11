extends DialogicSubsystem

## Subsystem that manages portraits and portrait positions.

signal character_joined(info:Dictionary)
signal character_left(info:Dictionary)
signal character_portrait_changed(info:Dictionary)
signal character_moved(info:Dictionary)

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

	# Load Position Portraits
	var portraits_info: Dictionary = dialogic.current_state_info.portraits.duplicate()
	dialogic.current_state_info.portraits = {}
	for character_path in portraits_info:
		var character_info: Dictionary = portraits_info[character_path]
		var character: DialogicCharacter = load(character_path)
		var container := dialogic.PortraitContainers.load_position_container(character.get_character_name())
		add_character(character, container, character_info.portrait, character_info.position_id)
		change_character_mirror(character, character_info.get('custom_mirror', false))
		change_character_z_index(character, character_info.get('z_index', 0))
		change_character_extradata(character, character_info.get('extra_data', ""))

	# Load Speaker Portrait
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
	if container == null:
		return null
	var character_node := Node2D.new()
	character_node.name = character.get_character_name()
	character_node.set_meta('character', character)
	container.add_child(character_node)
	return character_node


## Changes the portrait of a specific [character node].
func _change_portrait(character_node: Node2D, portrait: String, fade_animation:="", fade_length := 0.5) -> Dictionary:
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
	var previous_portrait: Node = null
	var portrait_count := character_node.get_child_count()

	if portrait_count > 0:
		previous_portrait = character_node.get_child(-1)

	# Check if the scene is the same as the currently loaded scene.
	if (not previous_portrait == null and
		previous_portrait.get_meta('scene', '') == scene_path and
		# Also check if the scene supports changing to the given portrait.
		previous_portrait._should_do_portrait_update(character, portrait)):
			portrait_node = previous_portrait
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
		portrait_node.set_meta('portrait', portrait)
		character_node.set_meta('portrait', portrait)

		DialogicUtil.apply_scene_export_overrides(portrait_node, character.portraits[portrait].get('export_overrides', {}))

		if portrait_node.has_method('_update_portrait'):
			portrait_node._update_portrait(character, portrait)

		if not portrait_node.is_inside_tree():
			character_node.add_child(portrait_node)

		_update_portrait_transform(portrait_node)

		## Handle Cross-Animating
		if previous_portrait and previous_portrait != portrait_node:
			if not fade_animation.is_empty() and fade_length > 0:
				var fade_out := _animate_node(previous_portrait, fade_animation, fade_length, 1, true)
				var _fade_in := _animate_node(portrait_node, fade_animation, fade_length, 1, false)
				fade_out.finished.connect(previous_portrait.queue_free)
			else:
				previous_portrait.queue_free()

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


func _update_character_transform(character_node:Node, time := 0.0) -> void:
	for child in character_node.get_children():
		_update_portrait_transform(child, time)


func _update_portrait_transform(portrait_node: Node, time:float = 0.0) -> void:
	var character_node: Node = portrait_node.get_parent()

	var character: DialogicCharacter = character_node.get_meta('character')
	var portrait_info: Dictionary = character.portraits.get(portrait_node.get_meta('portrait'), {})

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
			tween.stop()
	if time == 0:
		character_node.position = transform.position
		portrait_node.position = character.offset + portrait_info.get('offset', Vector2())
		portrait_node.scale = transform.size
	else:
		if not tween:
			tween = character_node.create_tween().set_parallel().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			character_node.set_meta('move_tween', tween)
			character_node.set_meta('move_time', time)
		tween.tween_method(DialogicUtil.multitween.bind(character_node, "position", "base"), character_node.position, transform.position, time)
		tween.tween_property(portrait_node, 'position',character.offset + portrait_info.get('offset', Vector2()), time)
		tween.tween_property(portrait_node, 'scale', transform.size, time)


## Animates the node with the given animation.
## Is used both on the character node (most animations) and the portrait nodes (cross-fade animations)
func _animate_node(node: Node, animation_path: String, length: float, repeats := 1, is_reversed := false) -> DialogicAnimation:
	if node.has_meta('animation_node') and is_instance_valid(node.get_meta('animation_node')):
		node.get_meta('animation_node').queue_free()

	var anim_script: Script = load(animation_path)
	var anim_node := Node.new()
	anim_node.set_script(anim_script)
	anim_node = (anim_node as DialogicAnimation)
	anim_node.node = node
	anim_node.orig_pos = node.position
	anim_node.end_position = node.position
	anim_node.time = length
	anim_node.repeats = repeats
	anim_node.is_reversed = is_reversed

	add_child(anim_node)
	anim_node.animate()

	node.set_meta("animation_path", animation_path)
	node.set_meta("animation_length", length)
	node.set_meta("animation_node", anim_node)

	#if not is_silent:
		#portrait_animating.emit(portrait_node.get_parent(), portrait_node, animation_path, length)

	return anim_node


## Moves the given portrait to the given container.
func _move_character(character_node: Node2D, transform:="", time := 0.0, easing:= Tween.EASE_IN_OUT, trans:= Tween.TRANS_SINE) -> void:
	var tween := character_node.create_tween().set_ease(easing).set_trans(trans).set_parallel()
	if time == 0:
		tween.kill()
		tween = null
	var container: DialogicNode_PortraitContainer = character_node.get_parent()
	dialogic.PortraitContainers.move_container(container, transform, tween, time)

	for portrait_node in character_node.get_children():
		_update_portrait_transform(portrait_node, time)


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
	portrait_node.get_parent().remove_child(portrait_node)
	portrait_node.queue_free()


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
func join_character(character:DialogicCharacter, portrait:String,  position_id:String, mirrored:= false, z_index:= 0, extra_data:= "", animation_name:= "", animation_length:= 0.0, animation_wait := false) -> Node:
	if is_character_joined(character):
		change_character_portrait(character, portrait)

		if animation_name.is_empty():
			animation_length = _get_join_default_length()

		if animation_wait:
			dialogic.current_state = DialogicGameHandler.States.ANIMATING
			await get_tree().create_timer(animation_length).timeout
			dialogic.current_state = DialogicGameHandler.States.IDLE
		move_character(character, position_id, animation_length)
		change_character_mirror(character, mirrored)
		return

	var container := dialogic.PortraitContainers.add_container(character.get_character_name())
	var character_node := add_character(character, container, portrait, position_id)
	if character_node == null:
		return null

	dialogic.current_state_info['portraits'][character.resource_path] = {'portrait':portrait, 'node':character_node, 'position_id':position_id, 'custom_mirror':mirrored}

	_change_portrait_mirror(character_node, mirrored)
	_change_portrait_extradata(character_node, extra_data)
	_change_portrait_z_index(character_node, z_index)

	var info := {'character':character}
	info.merge(dialogic.current_state_info['portraits'][character.resource_path])
	character_joined.emit(info)

	if animation_name.is_empty():
		animation_name = ProjectSettings.get_setting('dialogic/animations/join_default', "Fade In Up")
		animation_length = _get_join_default_length()
		animation_wait = ProjectSettings.get_setting('dialogic/animations/join_default_wait', true)

	animation_name = DialogicPortraitAnimationUtil.guess_animation(animation_name, DialogicPortraitAnimationUtil.AnimationType.IN)

	if animation_name and animation_length > 0:
		var anim: DialogicAnimation = _animate_node(character_node, animation_name, animation_length)
		if animation_wait:
			dialogic.current_state = DialogicGameHandler.States.ANIMATING
			await anim.finished
			dialogic.current_state = DialogicGameHandler.States.IDLE

	return character_node


func add_character(character:DialogicCharacter, container: DialogicNode_PortraitContainer, portrait:String,  position_id:String) -> Node:
	if is_character_joined(character):
		printerr('[DialogicError] Cannot add a already joined character. If this is intended call _create_character_node manually.')
		return null

	portrait = get_valid_portrait(character, portrait)

	if portrait.is_empty():
		return null

	if not character:
		printerr('[DialogicError] Cannot call add_portrait() with null character.')
		return null

	var character_node := _create_character_node(character, container)

	if character_node == null:
		printerr('[Dialogic] Failed to join character to position ', position_id, ". Could not find position container.")
		return null


	dialogic.current_state_info['portraits'][character.resource_path] = {'portrait':portrait, 'node':character_node, 'position_id':position_id}

	_move_character(character_node, position_id)
	_change_portrait(character_node, portrait)

	return character_node


## Changes the portrait of a character. Only works with joined characters.
func change_character_portrait(character: DialogicCharacter, portrait: String, fade_animation:="DEFAULT", fade_length := -1.0) -> void:
	if not is_character_joined(character):
		return

	portrait = get_valid_portrait(character, portrait)

	if dialogic.current_state_info.portraits[character.resource_path].portrait == portrait:
		return

	if fade_animation == "DEFAULT":
		fade_animation = ProjectSettings.get_setting('dialogic/animations/cross_fade_default', "Fade Cross")
		fade_length = ProjectSettings.get_setting('dialogic/animations/cross_fade_default_length', 0.5)

	fade_animation = DialogicPortraitAnimationUtil.guess_animation(fade_animation, DialogicPortraitAnimationUtil.AnimationType.CROSSFADE)

	var info := _change_portrait(dialogic.current_state_info.portraits[character.resource_path].node, portrait, fade_animation, fade_length)
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

	animation_path = DialogicPortraitAnimationUtil.guess_animation(animation_path)

	var character_node: Node = dialogic.current_state_info.portraits[character.resource_path].node

	return _animate_node(character_node, animation_path, length, repeats, is_reversed)


## Moves the given character to the given position. Only works with joined characters
func move_character(character:DialogicCharacter, position_id:String, time:= 0.0, easing:=Tween.EASE_IN_OUT, trans:=Tween.TRANS_SINE) -> void:
	if !is_character_joined(character):
		return

	if dialogic.current_state_info.portraits[character.resource_path].position_id == position_id:
		return

	_move_character(dialogic.current_state_info.portraits[character.resource_path].node, position_id, time, easing, trans)
	dialogic.current_state_info.portraits[character.resource_path].position_id = position_id
	character_moved.emit({'character':character, 'position_id':position_id, 'time':time})


## Removes a character with a given animation or the default animation.
func leave_character(character: DialogicCharacter, animation_name:= "", animation_length:= 0.0, animation_wait := false) -> void:
	if not is_character_joined(character):
		return

	if animation_name.is_empty():
		animation_name = ProjectSettings.get_setting('dialogic/animations/leave_default', "Fade Out Down")
		animation_length = _get_leave_default_length()
		animation_wait = ProjectSettings.get_setting('dialogic/animations/leave_default_wait', true)

	animation_name = DialogicPortraitAnimationUtil.guess_animation(animation_name, DialogicPortraitAnimationUtil.AnimationType.OUT)

	if not animation_name.is_empty():
		var character_node := get_character_node(character)

		var animation := _animate_node(character_node, animation_name, animation_length, 1, true)
		if animation_length > 0:
			if animation_wait:
				dialogic.current_state = DialogicGameHandler.States.ANIMATING
				await animation.finished
				dialogic.current_state = DialogicGameHandler.States.IDLE
				remove_character(character)
			else:
				animation.finished.connect(func(): remove_character(character))
		else:
			remove_character(character)


## Removes all joined characters with a given animation or the default animation.
func leave_all_characters(animation_name:="", animation_length:=0.0, animation_wait := false) -> void:
	for character in get_joined_characters():
		await leave_character(character, animation_name, animation_length, animation_wait)


## Finds the character node for a [param character].
## Return `null` if the [param character] is not part of the scene.
func get_character_node(character: DialogicCharacter) -> Node:
	if is_character_joined(character):
		if is_instance_valid(dialogic.current_state_info['portraits'][character.resource_path].node):
			return dialogic.current_state_info['portraits'][character.resource_path].node
	return null


## Removes the given characters portrait.
## Only works with joined characters.
func remove_character(character: DialogicCharacter) -> void:
	var character_node := get_character_node(character)

	if is_instance_valid(character_node) and character_node is Node:
		var container := character_node.get_parent()
		container.get_parent().remove_child(container)
		container.queue_free()
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
## Keys can be [joined, character, node (for the portrait node), position_id]
## Only joined is included (and false) for not joined characters
func get_character_info(character:DialogicCharacter) -> Dictionary:
	if is_character_joined(character):
		var info: Dictionary = dialogic.current_state_info['portraits'][character.resource_path]
		info['joined'] = true
		return info
	else:
		return {'joined':false}

#endregion


#region SPEAKER PORTRAIT CONTAINERS
####################################################################################################

## Updates all portrait containers set to SPEAKER.
func change_speaker(speaker: DialogicCharacter = null, portrait := "") -> void:
	for container: Node in get_tree().get_nodes_in_group('dialogic_portrait_con_speaker'):
		var just_joined := true
		for character_node: Node in container.get_children():
			if not character_node.get_meta('character') == speaker:
				var leave_animation: String = ProjectSettings.get_setting('dialogic/animations/leave_default', "Fade Out")
				leave_animation = DialogicPortraitAnimationUtil.guess_animation(leave_animation, DialogicPortraitAnimationUtil.AnimationType.OUT)
				var leave_animation_length := _get_leave_default_length()

				if leave_animation and leave_animation_length:
					var animate_out := _animate_node(character_node, leave_animation, leave_animation_length, 1, true)
					animate_out.finished.connect(character_node.queue_free)
				else:
					character_node.get_parent().remove_child(character_node)
					character_node.queue_free()
			else:
				just_joined = false

		if speaker == null or speaker.portraits.is_empty():
			continue

		if just_joined:
			_create_character_node(speaker, container)

		elif portrait.is_empty():
			continue

		if portrait.is_empty(): portrait = speaker.default_portrait

		var fade_animation: String = ProjectSettings.get_setting('dialogic/animations/cross_fade_default', "Fade Cross")
		var fade_length: float = ProjectSettings.get_setting('dialogic/animations/cross_fade_default_length', 0.5)

		fade_animation = DialogicPortraitAnimationUtil.guess_animation(fade_animation, DialogicPortraitAnimationUtil.AnimationType.CROSSFADE)

		if container.portrait_prefix+portrait in speaker.portraits:
			portrait = container.portrait_prefix+portrait

		_change_portrait(container.get_child(-1), portrait, fade_animation, fade_length)

		# if the character has no portraits _change_portrait won't actually add a child node
		if container.get_child(-1).get_child_count() == 0:
			continue

		if just_joined:
			var join_animation: String = ProjectSettings.get_setting('dialogic/animations/join_default', "Fade In Up")
			join_animation = DialogicPortraitAnimationUtil.guess_animation(join_animation, DialogicPortraitAnimationUtil.AnimationType.IN)
			var join_animation_length := _get_join_default_length()

			if join_animation and join_animation_length:
				_animate_node(container.get_child(-1), join_animation, join_animation_length)

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
