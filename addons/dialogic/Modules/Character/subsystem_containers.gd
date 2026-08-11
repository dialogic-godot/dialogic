extends DialogicSubsystem

## Subsystem that manages portrait positions.

signal position_changed(info: Dictionary)


var transform_regex := r"(?<part>position|pos|size|siz|rotation|rot)\W*=(?<value>((?!(pos|siz|rot)).)*)"

@export_group("State")
@export var container_info := {}


## Use this to update the debug_draw setting on all PortraitContainers currently in the tree.
var debug_draw := false :
	set(x):
		debug_draw = x
		for n:Node in get_tree().get_nodes_in_group(&'dialogic_portrait_con_position'):
			n.debug_draw = x
			n.queue_redraw()
		for n:Node in get_tree().get_nodes_in_group(&'dialogic_portrait_con_speaker'):
			n.debug_draw = x
			n.queue_redraw()


#region STATE
####################################################################################################


#endregion


#region MAIN METHODS
####################################################################################################

func get_container(position_id: String) -> DialogicNode_PortraitContainer:
	for portrait_position: DialogicNode_PortraitContainer in get_tree().get_nodes_in_group(&'dialogic_portrait_con_position'):
		if portrait_position.is_visible_in_tree() and portrait_position.is_container(position_id):
			return portrait_position
	return null


func get_containers(position_id: String) -> Array[DialogicNode_PortraitContainer]:
	return get_tree().get_nodes_in_group(&'dialogic_portrait_con_position').filter(
		func(node:DialogicNode_PortraitContainer):
			return node.is_visible_in_tree() and node.is_container(position_id))


## Creates a new portrait container node.
## It will copy it's size and most settings from the first p_container in the tree.
## It will be added as a sibling of the first p_container in the tree.
func add_container(position_id: String) -> DialogicNode_PortraitContainer:
	var example_position := get_tree().get_first_node_in_group(&'dialogic_portrait_con_position')
	if example_position:
		var new_position := DialogicNode_PortraitContainer.new()
		new_position.mode = DialogicNode_PortraitContainer.PositionModes._CHARACTER
		example_position.get_parent().add_child(new_position)
		new_position.name = "Portrait_"+position_id.validate_node_name()
		new_position.container_ids = [position_id]
		position_changed.emit({&'change':'added', &'container_node':new_position, &'position_id':position_id})
		return new_position
	return null


## Moves the [container] to the [destionation] (using [tween] and [time]).
## The destination can be a position_id (e.g. "center") or translation, rotation and scale.
## If full_update is false, the mirror and z_index will be preserved.
func update_container(container:DialogicNode_PortraitContainer, destination:String, time:float=0.0, easing:=Tween.EASE_IN_OUT, trans:=Tween.TRANS_SINE, full_update:=true) -> void:
	var to_settings : DialogicNode_PortraitContainer.ContainerSettings

	var destination_container := get_container(destination)
	if destination_container:
		to_settings = destination_container.current_settings.duplicate(true)
		if not full_update:
			to_settings.mirrored = container.current_settings.mirrored
			to_settings.z_index = container.current_settings.z_index
	else:
		to_settings = container.current_settings.duplicate(true)
		to_settings.update_from_string(destination)

	container.update_container(to_settings, time, easing, trans)

	save_position_container(container)


func save_position_container(container: DialogicNode_PortraitContainer) -> void:
	if container.target_settings:
		container_info[container.container_ids[0]] = container.target_settings.as_string()
	else:
		container_info[container.container_ids[0]] = container.current_settings.as_string()


func load_position_container(position_id: String) -> DialogicNode_PortraitContainer:
	# First check whether the container already exists:
	var container := get_container(position_id)
	if container:
		return container

	if not container_info.has(position_id):
		return null

	var info: String = container_info[position_id]
	container = add_container(position_id)

	if not container:
		return null

	var settings := DialogicNode_PortraitContainer.ContainerSettings.from_string(info)
	container.update_container(settings)
	return container
