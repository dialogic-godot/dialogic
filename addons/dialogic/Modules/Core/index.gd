@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [this_folder.path_join('event_end_branch.gd')]


func _get_subsystems() -> Array:
	return [
		{'name':'Expression', 'script':this_folder.path_join('subsystem_expression.gd')},
		{'name':'Animation', 'script':this_folder.path_join('subsystem_animation.gd')},
		{'name':'Input', 'script':this_folder.path_join('subsystem_input.gd')},
		]


func _get_text_effects() -> Array[Dictionary]:
	return [
		{'command':'aa', 'subsystem':'Input', 'method':'effect_autoadvance'},
		{'command':'ns', 'subsystem':'Input', 'method':'effect_noskip'},
		{'command':'input', 'subsystem':'Input', 'method':'effect_input'},
	]
