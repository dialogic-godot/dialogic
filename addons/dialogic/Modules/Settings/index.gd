@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [this_folder.path_join('event_setting.gd')]


func _get_subsystems() -> Array:
	return [{'name':'Settings', 'script':this_folder.path_join('subsystem_settings.gd')}]
