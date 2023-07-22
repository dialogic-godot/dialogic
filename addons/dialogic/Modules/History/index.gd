@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [this_folder.path_join('event_history.gd')]


func _get_subsystems() -> Array:
	return [{'name':'History', 'script':this_folder.path_join('subsystem_history.gd')}]

func _get_settings_pages() -> Array:
	return [this_folder.path_join('settings_history.tscn')]
