extends DialogicSubsystem

## Subsystem that manages portrait positions.

signal position_changed(info: Dictionary)


var transform_regex := r"(?<part>position|pos|size|siz|rotation|rot)\W*=(?<value>((?!(pos|siz|rot)).)*)"

#region STATE
####################################################################################################


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
	var any_portrait_container := get_tree().get_first_node_in_group(&'dialogic_portrait_con_position')
	if any_portrait_container:
		return any_portrait_container.get_parent()
	return null


## Creates a new portrait container node.
## It will copy it's size and most settings from the first p_container in the tree.
## It will be added as a sibling of the first p_container in the tree.
func add_container(position_id: String, position := "", size := "") -> DialogicNode_PortraitContainer:
	var example_position := get_tree().get_first_node_in_group(&'dialogic_portrait_con_position')
	if example_position:
		var new_position := DialogicNode_PortraitContainer.new()
		example_position.get_parent().add_child(new_position)
		new_position.name = "Portrait_"+position_id.validate_node_name()
		new_position.size = str_to_vector(size)
		copy_container_setup(example_position, new_position)
		new_position.container_ids = [position_id]
		new_position.position = str_to_vector(position)-new_position._get_origin_position()
		position_changed.emit({&'change':'added', &'container_node':new_position, &'position_id':position_id})
		return new_position
	return null


## Moves the [container] to the [destionation] (using [tween] and [time]).
## The destination can be a position_id (e.g. "center") or translation, roataion and scale.
## When moving to a preset container, then some more will be "copied" (e.g. anchors, etc.)
func move_container(container:DialogicNode_PortraitContainer, destination:String, tween:Tween = null, time:float=1.0) -> void:
	var target_position: Vector2 = container.position + container._get_origin_position()
	var target_rotation: float = container.rotation
	var target_size: Vector2 = container.size

	var destination_container := get_container(destination)
	if destination_container:
		container.set_meta("target_container", destination_container)
		target_position = destination_container.position + destination_container._get_origin_position()
		target_rotation = destination_container.rotation_degrees
		target_size = destination_container.size
	else:
		var regex := RegEx.create_from_string(transform_regex)
		for found in regex.search_all(destination):
			match found.get_string('part'):
				'pos', 'position':
					target_position = str_to_vector(found.get_string("value"), target_position)
				'rot', 'rotation':
					target_rotation = float(found.get_string("value"))
				'siz', 'size':
					target_size = str_to_vector(found.get_string("value"), target_size)
	translate_container(container, target_position, false, tween, time)
	rotate_container(container, target_rotation, false, tween, time)
	resize_container(container, target_size, false, tween, time)

	if destination_container:
		if time:
			tween.finished.connect(func():
				if container.has_meta("target_container"):
					if container.get_meta("target_container") == destination_container:
						copy_container_setup(destination_container, container)
				)
		else:
			copy_container_setup(destination_container, container)


func copy_container_setup(from:DialogicNode_PortraitContainer, to:DialogicNode_PortraitContainer) -> void:
	to.ignore_resize = true
	to.layout_mode = from.layout_mode
	to.anchors_preset = from.anchors_preset
	to.anchor_bottom = from.anchor_bottom
	to.anchor_left = from.anchor_left
	to.anchor_right = from.anchor_right
	to.anchor_top = from.anchor_top
	to.offset_bottom = from.offset_bottom
	to.offset_top = from.offset_top
	to.offset_right = from.offset_right
	to.offset_left = from.offset_left
	to.size_mode = from.size_mode
	to.origin_anchor = from.origin_anchor
	to.ignore_resize = false
	to.update_portrait_transforms()


func translate_container(container:DialogicNode_PortraitContainer, translation:Variant, relative := false, tween:Tween=null, time:float=1.0) -> void:
	if !container.has_meta(&'default_translation'):
		container.set_meta(&'default_translation', container.position+container._get_origin_position())

	var final_translation: Vector2
	if typeof(translation) == TYPE_STRING:
		final_translation = str_to_vector(translation, container.position+container._get_origin_position())
	elif typeof(translation) == TYPE_VECTOR2:
		final_translation = translation

	if relative:
		final_translation += container.position
	else:
		final_translation -= container._get_origin_position()

	if tween:
		tween.tween_method(DialogicUtil.multitween.bind(container, "position", "base"), container.position, final_translation, time)
		if not tween.finished.is_connected(save_position_container):
			tween.finished.connect(save_position_container.bind(container))
	else:
		container.position = final_translation
		save_position_container(container)
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
		if not tween.finished.is_connected(save_position_container):
			tween.finished.connect(save_position_container.bind(container))
	else:
		container.rotation_degrees = final_rotation
		save_position_container(container)

	position_changed.emit({&'change':'rotated', &'container_node':container})


func resize_container(container: DialogicNode_PortraitContainer, rect_size: Variant, relative := false, tween:Tween=null, time:float=1.0) -> void:
	if !container.has_meta(&'default_size'):
		container.set_meta(&'default_size', container.size)

	var final_rect_resize: Vector2
	if typeof(rect_size) == TYPE_STRING:
		final_rect_resize = str_to_vector(rect_size, container.size)
	elif typeof(rect_size) == TYPE_VECTOR2:
		final_rect_resize = rect_size

	if relative:
		final_rect_resize += container.rect_size

	var relative_position_change := container._get_origin_position()-container._get_origin_position(final_rect_resize)

	if tween:
		tween.tween_method(DialogicUtil.multitween.bind(container, "position", "resize_move"), Vector2(), relative_position_change, time)
		tween.tween_property(container, 'size', final_rect_resize, time)
		if not tween.finished.is_connected(save_position_container):
			tween.finished.connect(save_position_container.bind(container))
	else:
		container.position = container.position + relative_position_change
		container.set_deferred("size", final_rect_resize)
		save_position_container(container)

	position_changed.emit({&'change':'resized', &'container_node':container})


func save_position_container(container: DialogicNode_PortraitContainer) -> void:
	if not dialogic.current_state_info.has('portrait_containers'):
		dialogic.current_state_info['portrait_containers'] = {}

	var info := {
		"container_ids" : container.container_ids,
		"position" : container.position,
		"rotation" : container.rotation_degrees,
		"size" : container.size,
		"pivot_mode" : container.pivot_mode,
		"pivot_value" : container.pivot_value,
		"origin_anchor" : container.origin_anchor,
		"anchor_left" : container.anchor_left,
		"anchor_right" : container.anchor_right,
		"anchor_top" : container.anchor_top,
		"anchor_bottom" : container.anchor_bottom,
		"offset_left" : container.offset_left,
		"offset_right" : container.offset_right,
		"offset_top" : container.offset_top,
		"offset_bottom" : container.offset_bottom,
	}

	dialogic.current_state_info.portrait_containers[container.container_ids[0]] = info


func load_position_container(position_id: String) -> DialogicNode_PortraitContainer:
	# First check whether the container already exists:
	var container := get_container(position_id)
	if container:
		return container

	if not dialogic.current_state_info.has('portrait_containers') or not dialogic.current_state_info.portrait_containers.has(position_id):
		return null

	var info: Dictionary = dialogic.current_state_info.portrait_containers[position_id]
	container = add_container(position_id)

	if not container:
		return null

	container.container_ids = info.container_ids
	container.position = info.position
	container.rotation = info.rotation
	container.size = info.size
	container.pivot_mode = info.pivot_mode
	container.pivot_value = info.pivot_value
	container.origin_anchor = info.origin_anchor
	container.anchor_left = info.anchor_left
	container.anchor_right = info.anchor_right
	container.anchor_top = info.anchor_top
	container.anchor_bottom = info.anchor_bottom
	container.offset_left = info.offset_left
	container.offset_right = info.offset_right
	container.offset_top = info.offset_top
	container.offset_bottom = info.offset_bottom

	return container


func str_to_vector(input: String, base_vector:=Vector2()) -> Vector2:
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
