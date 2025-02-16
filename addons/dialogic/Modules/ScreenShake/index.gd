@tool
extends DialogicIndexer

func _get_events() -> Array:
	return [this_folder.path_join('event_screen_shake.gd')]

func _get_subsystems() -> Array:
	return [{'name':'ScreenShake', 'script':this_folder.path_join('subsystem_screen_shake.gd')}]
