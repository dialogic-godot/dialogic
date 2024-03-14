@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [this_folder.path_join('event_text.gd')]


func _get_subsystems() -> Array:
	return [{'name':'Text', 'script':this_folder.path_join('subsystem_text.gd')}]


func _get_settings_pages() -> Array:
	return [this_folder.path_join('settings_text.tscn')]


func _get_character_editor_sections() -> Array:
	return [this_folder.path_join('character_settings/character_moods_settings.tscn'),
		this_folder.path_join('character_settings/character_portrait_mood_settings.tscn'),
	]


func _get_text_effects() -> Array[Dictionary]:
	return [
		{'command':'speed', 'subsystem':'Text', 'method':'effect_speed', 'arg':true},
		{'command':'lspeed', 'subsystem':'Text', 'method':'effect_lspeed', 'arg':true},
		{'command':'pause', 'subsystem':'Text', 'method':'effect_pause', 'arg':true},
		{'command':'signal', 'subsystem':'Text', 'method':'effect_signal', 'arg':true},
		{'command':'mood', 'subsystem':'Text', 'method':'effect_mood', 'arg':true},
	]


func _get_text_modifiers() -> Array[Dictionary]:
	return [
		{'subsystem':'Text', 'method':'modifier_autopauses'},
		{'subsystem':'Text', 'method':'modifier_random_selection', 'mode':-1},
		{'subsystem':'Text', 'method':"modifier_break", 'command':'br', 'mode':-1},
	]
