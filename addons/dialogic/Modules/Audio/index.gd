@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [this_folder.path_join('event_music.gd'), this_folder.path_join('event_sound.gd')]


func _get_subsystems() -> Array:
	return [{'name':'Audio', 'script':this_folder.path_join('subsystem_audio.gd')}]


func _get_settings_pages() -> Array:
	return [this_folder.path_join('settings_audio.tscn')]
