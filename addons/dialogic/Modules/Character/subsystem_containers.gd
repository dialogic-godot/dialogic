extends DialogicSubsystem

## Subsystem that manages portrait positions.

signal position_changed(info:Dictionary)

#region STATE
####################################################################################################

func clear_game_state(clear_flag:=DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	pass


func load_game_state(load_flag:=LoadFlags.FULL_LOAD) -> void:
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

func get_portrait_container(position_id:String) -> DialogicNode_PortraitContainer:
	for portrait_position:DialogicNode_PortraitContainer in get_tree().get_nodes_in_group('dialogic_portrait_con_position'):
		if portrait_position.is_visible_in_tree() and portrait_position.is_container(position_id):
			return portrait_position
	return null


func get_portrait_containers(position_id:String) -> Array[DialogicNode_PortraitContainer]:
	return get_tree().get_nodes_in_group('dialogic_portrait_con_position').filter(
		func(node:DialogicNode_PortraitContainer):
			return node.is_visible_in_tree() and node.is_container(position_id))


## Creates a new portrait container node.
## It will copy it's size and most settings from the first p_container in the tree.
## It will be added as a sibling of the first p_container in the tree.
func add_portrait_position(position_id: String, position:Vector2) -> void:
	var example_position := get_tree().get_first_node_in_group('dialogic_portrait_con_position')
	if example_position:
		var new_position := DialogicNode_PortraitContainer.new()
		example_position.get_parent().add_child(new_position)
		new_position.size = example_position.size
		new_position.size_mode = example_position.size_mode
		new_position.origin_anchor = example_position.origin_anchor
		new_position.container_ids = [position_id]
		new_position.position = position-new_position._get_origin_position()
		position_changed.emit({'change':'added', 'container_node':new_position, 'position_id':position_id})


func move_portrait_position(position_id: String, vector:Vector2, relative:= false, time:= 0.0) -> void:
	var portrait_container := get_portrait_container(position_id)
	if portrait_container:
		if !portrait_container.has_meta('default_position'):
			portrait_container.set_meta('default_position', portrait_container.position)
		var tween := portrait_container.create_tween()
		if !relative:
			tween.tween_property(portrait_container, 'position', vector, time)
		else:
			tween.tween_property(portrait_container, 'position', vector, time).as_relative()
		position_changed.emit({'change':'moved', 'container_node':portrait_container, 'position_id':position_id})

	else:
		# If this is reached, no position could be found. If the position is absolute, we will just add it.
		if !relative:
			add_portrait_position(position_id, vector)


func reset_all_portrait_positions(time:= 0.0) -> void:
	for portrait_position in get_tree().get_nodes_in_group('dialogic_portrait_con_position'):
		if portrait_position.is_visible_in_tree():
			if portrait_position.has_meta('default_position'):
				move_portrait_position(portrait_position.position_index, portrait_position.get_meta('default_position'), false, time)


func reset_portrait_position(position_id:String, time:= 0.0) -> void:
	for portrait_position in get_portrait_containers(position_id):
		if portrait_position.has_meta('default_position'):
			move_portrait_position(position_id, portrait_position.get_meta('default_position'), false, time)
