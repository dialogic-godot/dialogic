@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [this_folder.path_join('event_jump.gd'), this_folder.path_join('event_label.gd'), this_folder.path_join('event_return.gd')]

func _get_subsystems() -> Array:
	return [{'name':'Jump', 'script':this_folder.path_join('subsystem_jump.gd')}]
