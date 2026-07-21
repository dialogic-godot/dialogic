@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [this_folder.path_join('event_wait.gd')]


func _get_subsystems() -> Array:
	return [{'name':'Wait', 'script':this_folder.path_join('subsystem_wait.gd')}]
