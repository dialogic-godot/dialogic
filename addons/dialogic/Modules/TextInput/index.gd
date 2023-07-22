@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [this_folder.path_join('event_text_input.gd')]


func _get_subsystems() -> Array:
	return [{'name':'TextInput', 'script':this_folder.path_join('subsystem_text_input.gd')}]

