extends DialogicSubsystem

## Subsystem that manages portrait positions.

signal position_changed(info: Dictionary)

#region STATE
####################################################################################################

func clear_game_state(clear_flag := DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	pass


func load_game_state(load_flag := LoadFlags.FULL_LOAD) -> void:
	pass


func pause() -> void:
	pass


func resume() -> void:
	pass


func _ready() -> void:
	pass

#endregion


#region MAIN METHODS
####################################################################################################

func get_container(position_id: String) -> DialogicNode_PortraitContainer:
	for portrait_position:DialogicNode_PortraitContainer in get_tree().get_nodes_in_group(&'dialogic_portrait_con_position'):
		if portrait_position.is_visible_in_tree() and portrait_position.is_container(position_id):
			return portrait_position
	return null


func get_containers(position_id: String) -> Array[DialogicNode_PortraitContainer]:
	return get_tree().get_nodes_in_group(&'dialogic_portrait_con_position').filter(
		func(node:DialogicNode_PortraitContainer):
			return node.is_visible_in_tree() and node.is_container(position_id))


func get_container_container() -> CanvasItem:
	var any_portrait := get_tree().get_first_node_in_group(&'dialogic_portrait_con_position')
	if any_portrait:
		return any_portrait.get_parent()
	return null


## Creates a new portrait container node.
## It will copy it's size and most settings from the first p_container in the tree.
## It will be added as a sibling of the first p_container in the tree.
func add_container(position_id: String, position := "", size := "") -> DialogicNode_PortraitContainer:
	var example_position := get_tree().get_first_node_in_group(&'dialogic_portrait_con_position')
	if example_position:
		var new_position := DialogicNode_PortraitContainer.new()
		example_position.get_parent().add_child(new_position)
		new_position.size = str_to_vector(size)
		new_position.size_mode = example_position.size_mode
		new_position.origin_anchor = example_position.origin_anchor
		new_position.container_ids = [position_id]
		new_position.position = str_to_vector(position)-new_position._get_origin_position()
		position_changed.emit({&'change':'added', &'container_node':new_position, &'position_id':position_id})
		return new_position
	return null


func translate_container(container:DialogicNode_PortraitContainer, translation:String, relative := false, tween:Tween=null, time:float=1.0) -> void:
	if !container.has_meta(&'default_translation'):
		container.set_meta(&'default_translation', container.position+container._get_origin_position())

	var final_translation := str_to_vector(translation, container.position+container._get_origin_position())

	if relative:
		final_translation += container.position
	else:
		final_translation -= container._get_origin_position()

	if tween:
		tween.tween_method(DialogicUtil.multitween.bind(container, "position", "base"), container.position, final_translation, time)
	else:
		container.position = final_translation
	position_changed.emit({&'change':'moved', &'container_node':container})

func rotate_container(container:DialogicNode_PortraitContainer, rotation:float, relative := false, tween:Tween=null, time:float=1.0) -> void:
	if !container.has_meta(&'default_rotation'):
		container.set_meta(&'default_rotation', container.rotation_degrees)

	var final_rotation := rotation

	if relative:
		final_rotation += container.rotation_degrees

	container.pivot_offset = container._get_origin_position()

	if tween:
		tween.tween_property(container, 'rotation_degrees', final_rotation, time)
	else:
		container.rotation_degrees = final_rotation

	position_changed.emit({&'change':'rotated', &'container_node':container})

func resize_container(container: DialogicNode_PortraitContainer, rect_size: String, relative := false, tween:Tween=null, time:float=1.0) -> void:
	if !container.has_meta(&'default_size'):
		container.set_meta(&'default_size', container.size)

	var final_rect_resize := str_to_vector(rect_size, container.size)

	if relative:
		final_rect_resize += container.rect_size

	var relative_position_change := container._get_origin_position()-container._get_origin_position(final_rect_resize)

	if tween:
		tween.tween_method(DialogicUtil.multitween.bind(container, "position", "resize_move"), Vector2(), relative_position_change, time)
		tween.tween_property(container, 'size', final_rect_resize, time)
	else:
		container.position = container.position + relative_position_change
		container.size = final_rect_resize

	position_changed.emit({&'change':'resized', &'container_node':container})


func str_to_vector(input: String, base_vector := Vector2()) -> Vector2:
	var vector_regex := RegEx.create_from_string(r"(?<part>x|y)\s*(?<number>(-|\+)?(\d|\.|)*)(\s*(?<type>%|px))?")
	var vec := base_vector
	for i in vector_regex.search_all(input):
		var value := float(i.get_string(&'number'))
		match i.get_string(&'type'):
			'px':
				pass # Keep values as they are
			'%', _:
				match i.get_string(&'part'):
					'x': value *= get_viewport().get_window().size.x
					'y': value *= get_viewport().get_window().size.y

		match i.get_string(&'part'):
			'x': vec.x = value
			'y': vec.y = value
	return vec


func vector_to_str(vec:Vector2) -> String:
	return "x" + str(vec.x) + "px y" + str(vec.y) + "px"


func reset_all_containers(time:= 0.0, tween:Tween = null) -> void:
	for container in get_tree().get_nodes_in_group(&'dialogic_portrait_con_position'):
		reset_container(container, time, tween)


func reset_container(container:DialogicNode_PortraitContainer, time := 0.0, tween: Tween = null ) -> void:
	if container.has_meta(&'default_translation'):
		translate_container(container, vector_to_str(container.get_meta(&'default_translation')), false, tween, time)
	if container.has_meta(&'default_rotation'):
		rotate_container(container, container.get_meta(&'default_rotation'), false, tween, time)
	if container.has_meta(&'default_size'):
		resize_container(container, vector_to_str(container.get_meta(&'default_size')), false, tween, time)