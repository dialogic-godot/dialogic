@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [this_folder.path_join('event_save.gd')]


func _get_subsystems() -> Array:
	return [{'name':'Save', 'script':this_folder.path_join('subsystem_save.gd')}]


func _get_settings_pages() -> Array:
	return [this_folder.path_join('settings_save.tscn')]
