@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [this_folder.path_join('event_style.gd')]


func _get_subsystems() -> Array:
	return [{'name':'Styles', 'script':this_folder.path_join('subsystem_styles.gd')}]


func _get_character_editor_sections() -> Array:
	return [this_folder.path_join('character_settings_style.tscn')]
