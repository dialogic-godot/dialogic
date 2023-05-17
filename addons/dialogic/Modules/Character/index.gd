@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [this_folder.path_join('event_character.gd'), this_folder.path_join('event_position.gd')]


func _get_subsystems() -> Array:
	return [{'name':'Portraits', 'script':this_folder.path_join('subsystem_portraits.gd')}]


func _get_settings_pages() -> Array:
	return [this_folder.path_join('settings_portraits.tscn')]

func _get_text_effects() -> Array[Dictionary]:
	return [{'command':'portrait', 'subsystem':'Portraits', 'method':'text_effect_portrait'}]
