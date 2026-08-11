extends DialogicSubsystem

## Subsystem that manages portraits and portrait positions.

signal character_joined(info:Dictionary)
signal character_left(info:Dictionary)
signal character_portrait_changed(info:Dictionary)
signal character_moved(info:Dictionary)

## Emitted when a portrait starts animating.
#signal portrait_animating(character_node: Node, portrait_node: Node, animation_name: String, animation_length: float)

@export_group("State")
@export var portraits := {}

var character_nodes: Dictionary[String, Node] = {}

## The default portrait scene.
var default_portrait_scene: PackedScene = load(get_script().resource_path.get_base_dir().path_join('default_portrait.tscn'))


#region STATE
####################################################################################################

func _clear_state(_clear_flag := DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	for character_node in character_nodes.values():
		_remove_character(character_node)
	portraits.clear()
	character_nodes.clear()


func _load_state(_load_flag := LoadFlags.FULL_LOAD) -> void:
	# Load Position Portraits
	var portraits_info: Dictionary = portraits.duplicate()
	portraits = {}
	var portrait_states: Dictionary = get_extra_state().get("portrait_state", {})
	for character_identifier in portraits_info:
		var character_info: Dictionary = portraits_info[character_identifier]
		var character: DialogicCharacter = DialogicResourceUtil.get_character_resource(character_identifier)
		if character:
			var container := dialogic.PortraitContainers.load_position_container(character.get_character_name())
			await add_character(character, container, character_info.portrait, character_info.position_id)
			character_nodes[character.get_identifier()].get_child(-1)._load_state(portrait_states.get(character.get_identifier(), {}))
		else:
			push_error('[Dialogic] Failed to load character "' + str(character_identifier) + '".')

	# Load Speaker Portrait
	var speaker: Variant = dialogic.Text.speaker_identifier
	if speaker:
		# TODO ??
		dialogic.Text.speaker_identifier = ""
		change_speaker(DialogicResourceUtil.get_character_resource(speaker))
	dialogic.Text.speaker_identifier = speaker


func _pack_extra_state() -> Dictionary:
	var portrait_state := {}
	for i in character_nodes:
		portrait_state[i] = character_nodes[i].get_child(-1)._get_state()
	return {"portrait_state":portrait_state}


func _pause() -> void:
	for node in character_nodes.values():
		if node.has_meta('animation_node'):
			node.get_meta('animation_node').pause()


func _resume() -> void:
	for node in character_nodes.values():
		if node.has_meta('animation_node'):
			node.get_meta('animation_node').resume()


func _ready() -> void:
	if not ProjectSettings.get_setting('dialogic/portraits/default_portrait', '').is_empty():
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
	character_node.name = character.get_character_name().validate_node_name()
	character_node.set_meta("character", character)
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
	var copy_state_vars := {}

	if portrait_count > 0:
		previous_portrait = character_node.get_child(-1)

	# Check if the scene is the same as the currently loaded scene.
	if previous_portrait != null and previous_portrait.get_meta("scene", "") == scene_path:
		# Also check if the scene supports changing to the given portrait.
		if previous_portrait is DialogicPortrait:
			for i in previous_portrait.get_property_list():
				if i.name.begins_with("state_"):
					copy_state_vars[i.name] = previous_portrait.get(i.name)
			if previous_portrait._should_do_portrait_update(character, portrait):
				portrait_node = previous_portrait
				info["same_scene"] = true

	if portrait_node == null:
		if previous_portrait: previous_portrait.name = "Previous_Portrait"
		if ResourceLoader.exists(scene_path):
			ResourceLoader.load_threaded_request(scene_path)

			var load_status := ResourceLoader.load_threaded_get_status(scene_path)
			while load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				await get_tree().process_frame
				load_status = ResourceLoader.load_threaded_get_status(scene_path)

			if load_status == ResourceLoader.THREAD_LOAD_LOADED:
				var packed_scene: PackedScene = ResourceLoader.load_threaded_get(scene_path)
				if packed_scene:
					portrait_node = packed_scene.instantiate()
				else:
					push_error('[Dialogic] Portrait node "' + str(scene_path) + '" for character [' + character.display_name + '] could not be loaded. Your portrait might not show up on the screen. Confirm the path is correct.')
			else:
				push_error('[Dialogic] Failed to load portrait node "' + str(scene_path) + '" for character [' + character.display_name + '].')

		if not portrait_node:
			portrait_node = default_portrait_scene.instantiate()
			portrait_node.name = portrait.validate_node_name()

		portrait_node.set_meta('scene', scene_path)


	if portrait_node:
		for i in copy_state_vars:
			if i in portrait_node:
				portrait_node.set(i, copy_state_vars[i])

		portrait_node.set_meta('portrait', portrait)
		character_node.set_meta('portrait', portrait)

		DialogicUtil.apply_scene_export_overrides(portrait_node, character.portraits[portrait].get('export_overrides', {}))

		if portrait_node.has_method('_update_portrait'):
			portrait_node._update_portrait(character, portrait)

		if not portrait_node.is_inside_tree():
			character_node.add_child(portrait_node)

		## Handle Cross-Animating
		if previous_portrait and previous_portrait != portrait_node:
			if not fade_animation.is_empty() and fade_length > 0:
				var fade_out := _animate_node(previous_portrait, fade_animation, fade_length, 1, true)
				var _fade_in := _animate_node(portrait_node, fade_animation, fade_length, 1, false)
				fade_out.finished.connect(previous_portrait.queue_free)
			else:
				previous_portrait.queue_free()

	return info


## Changes the mirroring of the given character.
func _change_portrait_mirror(character_node: Node2D, mirrored := false) -> void:
	dialogic.PortraitContainers.update_container(character_node.get_parent(), "mir="+str(mirrored), 0)


func _change_portrait_extradata(character_node: Node2D, extra_data := "") -> void:
	if not is_instance_valid(character_node):
		push_error("[Dialogic] Invalid character node provided.")
		return

	if character_node.get_child_count() > 0:
		var latest_portrait := character_node.get_child(-1)

		if latest_portrait and latest_portrait.has_method("_set_extra_data"):
			latest_portrait._set_extra_data(extra_data)
	else:
		push_warning("[Dialogic] No portrait found for character node: " + character_node.name)


## Animates the node with the given animation.
## Is used both on the character node (most animations) and the portrait nodes (cross-fade animations)
func _animate_node(node: Node, animation_path: String, length: float, repeats := 1, is_reversed := false, repeat_forever := false) -> DialogicAnimation:
	if node.has_meta('animation_node') and is_instance_valid(node.get_meta('animation_node')):
		node.get_meta('animation_node').queue_free()

	var anim_script: Script = load(animation_path)
	var anim_node := Node.new()
	anim_node.set_script(anim_script)
	anim_node = (anim_node as DialogicAnimation)
	anim_node.name = node.name +"_"+animation_path.get_file().trim_suffix(".gd").validate_node_name()
	anim_node.node = node
	anim_node.base_position = node.position
	anim_node.base_scale = node.scale
	anim_node.time = length
	anim_node.repeats = repeats
	anim_node.repeat_forever = repeat_forever
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
	var container: DialogicNode_PortraitContainer = character_node.get_parent()
	dialogic.PortraitContainers.update_container(container, transform, time, easing, trans)#, false)


## Changes the given characters z_index.
func _change_portrait_z_index(character_node: Node, z_index:int, update_zindex:= true) -> void:
	if update_zindex:
		dialogic.PortraitContainers.update_container(character_node.get_parent(), "z="+str(z_index), 0)


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
		var portrait_node: DialogicPortrait = character_nodes[character.get_identifier()].get_child(-1)
		return portrait_node

	return null


## Private method to remove a [param portrait_node].
func _remove_portrait(portrait_node: Node) -> void:
	portrait_node.get_parent().remove_child(portrait_node)
	portrait_node.queue_free()



## Removes the given characters portrait.
## Only works with joined characters.
func _remove_character(character_node:Node) -> void:
	if is_instance_valid(character_node) and character_node is Node:
		character_left.emit({'character': character_node.get_meta("character")})
		var container := character_node.get_parent()
		container.get_parent().remove_child(container)
		container.queue_free()
		character_node.queue_free()



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
			printerr('[Dialogic] Tried to use invalid portrait "', portrait, '" on character "', character.get_character_name(), '". Using default portrait instead.')
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
	var character_node := await add_character(character, container, portrait, position_id)
	if character_node == null:
		return null

	portraits[character.get_identifier()] = {'portrait':portrait, 'position_id':position_id}
	character_nodes[character.get_identifier()] = character_node

	_change_portrait_mirror(character_node, mirrored)
	_change_portrait_extradata(character_node, extra_data)
	_change_portrait_z_index(character_node, z_index)

	var info := {'character':character}
	info.merge(portraits[character.get_identifier()])
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


func add_character(character: DialogicCharacter, container: DialogicNode_PortraitContainer, portrait: String, transform: String) -> Node:
	if is_character_joined(character):
		printerr('[DialogicError] Cannot add an already joined character. If this is intended, call _create_character_node manually.')
		return null

	portrait = get_valid_portrait(character, portrait)

	if portrait.is_empty():
		return null

	if not character:
		printerr('[DialogicError] Cannot call add_character() with null character.')
		return null

	var character_node := _create_character_node(character, container)

	if character_node == null:
		printerr('[Dialogic] Failed to join character to position ', transform, ". Could not find position container.")
		return null

	portraits[character.get_identifier()] = {'portrait': portrait, 'position_id': transform}
	character_nodes[character.get_identifier()] = character_node

	_move_character(character_node, transform)
	await _change_portrait(character_node, portrait)

	return character_node


## Changes the portrait of a character. Only works with joined characters.
func change_character_portrait(character: DialogicCharacter, portrait: String, fade_animation:="", fade_length := -1.0) -> void:
	if not is_character_joined(character):
		return

	portrait = get_valid_portrait(character, portrait)

	if portraits[character.get_identifier()].portrait == portrait:
		return

	if fade_animation == "":
		fade_animation = ProjectSettings.get_setting('dialogic/animations/cross_fade_default', "Fade Cross")
		fade_length = ProjectSettings.get_setting('dialogic/animations/cross_fade_default_length', 0.5)

	fade_animation = DialogicPortraitAnimationUtil.guess_animation(fade_animation, DialogicPortraitAnimationUtil.AnimationType.CROSSFADE)

	var info := await _change_portrait(character_nodes[character.get_identifier()], portrait, fade_animation, fade_length)
	portraits[character.get_identifier()].portrait = info.portrait
	character_portrait_changed.emit(info)


## Changes the mirror of the given character. Only works with joined characters
func change_character_mirror(character:DialogicCharacter, mirrored:= false) -> void:
	if not is_character_joined(character):
		return

	_change_portrait_mirror(character_nodes[character.get_identifier()], mirrored)


## Changes the z_index of a character. Only works with joined characters
func change_character_z_index(character:DialogicCharacter, z_index:int, update_zindex:= true) -> void:
	if not is_character_joined(character):
		return

	_change_portrait_z_index(character_nodes[character.get_identifier()], z_index, update_zindex)
	if update_zindex:
		portraits[character.get_identifier()]['z_index'] = z_index


## Changes the extra data on the given character. Only works with joined characters
func change_character_extradata(character:DialogicCharacter, extra_data:="") -> void:
	if not is_character_joined(character):
		return
	_change_portrait_extradata(character_nodes[character.get_identifier()], extra_data)
	portraits[character.get_identifier()]['extra_data'] = extra_data


## Starts the given animation on the given character. Only works with joined characters
func animate_character(character: DialogicCharacter, animation_path: String, length: float, repeats := 1, is_reversed := false, repeat_forever := false) -> DialogicAnimation:
	if not is_character_joined(character):
		return null

	animation_path = DialogicPortraitAnimationUtil.guess_animation(animation_path)

	var character_node: Node = character_nodes[character.get_identifier()]

	return _animate_node(character_node, animation_path, length, repeats, is_reversed, repeat_forever)



## Moves the given character to the given position. Only works with joined characters
func move_character(character:DialogicCharacter, position_id:String, time:= 0.0, easing:=Tween.EASE_IN_OUT, trans:=Tween.TRANS_SINE) -> void:
	if not is_character_joined(character):
		return

	if portraits[character.get_identifier()].position_id == position_id:
		return

	_move_character(character_nodes[character.get_identifier()], position_id, time, easing, trans)
	portraits[character.get_identifier()].position_id = position_id
	character_moved.emit({'character':character, 'position_id':position_id, 'time':time})


## Removes a character with a given animation or the default animation.
func leave_character(character: DialogicCharacter, animation_name:= "", animation_length:= 0.0, animation_wait := false) -> void:
	if not is_character_joined(character):
		return

	var character_node := get_character_node(character)

	# We do this BEFORE the animation actually finishes
	# because it's possible the character joines again while leaving.
	portraits.erase(character.get_identifier())
	character_nodes.erase(character.get_identifier())

	if animation_name.is_empty():
		animation_name = ProjectSettings.get_setting('dialogic/animations/leave_default', "Fade Out Down")
		animation_length = _get_leave_default_length()
		animation_wait = ProjectSettings.get_setting('dialogic/animations/leave_default_wait', true)

	animation_name = DialogicPortraitAnimationUtil.guess_animation(animation_name, DialogicPortraitAnimationUtil.AnimationType.OUT)

	if not animation_name.is_empty():
		var animation := _animate_node(character_node, animation_name, animation_length, 1, true)
		if animation_length > 0:
			if animation_wait:
				dialogic.current_state = DialogicGameHandler.States.ANIMATING
				await animation.finished
				dialogic.current_state = DialogicGameHandler.States.IDLE
				_remove_character(character_node)
			else:
				animation.finished.connect(_remove_character.bind(character_node))
		else:
			_remove_character(character_node)


## Removes all joined characters with a given animation or the default animation.
func leave_all_characters(animation_name:="", animation_length:=0.0, animation_wait := false) -> void:
	for character in get_joined_characters():
		await leave_character(character, animation_name, animation_length, animation_wait)


## Finds the character node for a [param character].
## Return `null` if the [param character] is not part of the scene.
func get_character_node(character: DialogicCharacter) -> Node:
	if is_character_joined(character):
		if is_instance_valid(character_nodes[character.get_identifier()]):
			return character_nodes[character.get_identifier()]
	return null


## Returns true if the given character is currently joined.
func is_character_joined(character: DialogicCharacter) -> bool:
	if character == null or not character.get_identifier() in portraits:
		return false

	return true


## Returns a list of the joined charcters (as resources)
func get_joined_characters() -> Array[DialogicCharacter]:
	var chars: Array[DialogicCharacter] = []

	for char_identifier: String in portraits.keys():
		chars.append(DialogicResourceUtil.get_character_resource(char_identifier))

	return chars


## Returns a dictionary with info on a given character.
## Keys can be [joined, character, node (for the portrait node), position_id]
## Only joined is included (and false) for not joined characters
func get_character_info(character:DialogicCharacter) -> Dictionary:
	if is_character_joined(character):
		var info: Dictionary = portraits[character.get_identifier()]
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
					await animate_out.finished
					character_node.queue_free()
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
		if portrait.is_empty():
			if is_character_joined(speaker):
				portrait = portraits[speaker.get_identifier()].get("portrait", "")
		if portrait.is_empty():
			portrait = speaker.default_portrait

		var character_node := container.get_child(-1)

		var fade_animation: String = ProjectSettings.get_setting('dialogic/animations/cross_fade_default', "Fade Cross")
		var fade_length: float = ProjectSettings.get_setting('dialogic/animations/cross_fade_default_length', 0.5)

		fade_animation = DialogicPortraitAnimationUtil.guess_animation(fade_animation, DialogicPortraitAnimationUtil.AnimationType.CROSSFADE)

		if container.portrait_prefix + portrait in speaker.portraits:
			portrait = container.portrait_prefix + portrait

		await _change_portrait(character_node, portrait, fade_animation, fade_length)

		# if the character has no portraits _change_portrait won't actually add a child node
		if character_node.get_child_count() == 0:
			continue

		if just_joined:
			# Change speaker is called before the text is changed.
			# In styles where the speaker is IN the textbox,
			# this can mean the portrait container isn't sized correctly yet.
			character_node.hide()
			if not container.is_visible_in_tree():
				await get_tree().process_frame

			# There is chance that the style changed (due to a speaker style) and thus the character node is gone now.
			# In that case, just give up.
			if not is_instance_valid(character_node):
				return
			character_node.show()
			var join_animation: String = ProjectSettings.get_setting('dialogic/animations/join_default', "Fade In Up")
			join_animation = DialogicPortraitAnimationUtil.guess_animation(join_animation, DialogicPortraitAnimationUtil.AnimationType.IN)
			var join_animation_length := _get_join_default_length()

			if join_animation and join_animation_length:
				await _animate_node(character_node, join_animation, join_animation_length).finished

	var prev_speaker: DialogicCharacter = dialogic.Text.get_current_speaker()
	if speaker != prev_speaker:
		if is_character_joined(prev_speaker):
			character_nodes[prev_speaker.get_identifier()].get_child(-1)._unhighlight()

		if is_character_joined(speaker):
			character_nodes[speaker.get_identifier()].get_child(-1)._highlight()

#endregion


#region TEXT EFFECTS
####################################################################################################

## Called from the [portrait=something] text effect.
func text_effect_portrait(_text_node:Control, _skipped:bool, argument:String) -> void:
	if argument:
		var current_speaker := dialogic.Text.get_current_speaker()
		if current_speaker:
			change_character_portrait(current_speaker, argument)
			change_speaker(current_speaker, argument)


## Called from the [extra_data=something] text effect.
func text_effect_extradata(_text_node:Control, _skipped:bool, argument:String) -> void:
	if argument:
		if dialogic.Text.get_current_speaker():
			change_character_extradata(dialogic.Text.get_current_speaker(), argument)
#endregion
