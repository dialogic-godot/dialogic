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


func _get_text_effects() -> Array[Dictionary]:
	return [
		{'command':'speed', 'subsystem':'Text', 'method':'effect_speed'},
		{'command':'pause', 'subsystem':'Text', 'method':'effect_pause'},
		{'command':'signal', 'subsystem':'Text', 'method':'effect_signal'},
		{'command':'mood', 'subsystem':'Text', 'method':'effect_mood'},
		{'command':'aa', 'subsystem':'Text', 'method':'effect_autoadvance'},
		{'command':'ns', 'subsystem':'Text', 'method':'effect_noskip'},
	]


func _get_text_modifiers() -> Array[Dictionary]:
	return [
		{'subsystem':'Text', 'method':'modifier_random_selection'},
		{'subsystem':'Text', 'method':"modifier_break", 'command':'br'},
		
	]
