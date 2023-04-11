@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [this_folder.path_join('event_variable.gd')]

func _get_editors() -> Array:
	return [this_folder.path_join('variables_editor/variables_editor.tscn')]

func _get_subsystems() -> Array:
	return [{'name':'VAR', 'script':this_folder.path_join('subsystem_variables.gd')}]
