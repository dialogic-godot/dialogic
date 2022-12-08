@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [this_folder.path_join('event_voice.gd')]


func _get_subsystems() -> Array:
	return [{'name':'Voice', 'script':this_folder.path_join('subsystem_voice.gd')}]
