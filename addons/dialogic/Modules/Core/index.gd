@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [this_folder.path_join('event_end_branch.gd')]


func _get_subsystems() -> Array:
	return [
		{'name':'Expression', 'script':this_folder.path_join('subsystem_expression.gd')},
		{'name':'Animation', 'script':this_folder.path_join('subsystem_animation.gd')},
		]
