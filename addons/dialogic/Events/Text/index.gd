@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [this_folder.path_join('event_text.gd')]


func _get_subsystems() -> Array:
	return [{'name':'Text', 'script':this_folder.path_join('subsystem_text.gd')}]


func _get_settings_pages() -> Array:
	return [this_folder.path_join('settings_text.tscn')]


func _get_character_editor_tabs() -> Array:
	return [this_folder.path_join('character_settings/character_settings_text.tscn')]
