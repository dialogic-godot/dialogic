@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [this_folder.path_join('event_end_branch.gd')]


func _get_subsystems() -> Array:
	return [
		{'name':'Expressions', 'script':this_folder.path_join('subsystem_expression.gd')},
		{'name':'Animations', 'script':this_folder.path_join('subsystem_animation.gd')},
		{'name':'Inputs', 'script':this_folder.path_join('subsystem_input.gd')},
		]


func _get_text_effects() -> Array[Dictionary]:
	return [
		{'command':'aa', 'subsystem':'Inputs', 'method':'effect_autoadvance'},
		{'command':'ns', 'subsystem':'Inputs', 'method':'effect_noskip'},
		{'command':'input', 'subsystem':'Inputs', 'method':'effect_input'},
	]

func _get_text_modifiers() -> Array[Dictionary]:
	return [
		{'subsystem':'Expressions', 'method':"modifier_condition", 'command':'if', 'mode':-1},
	]
