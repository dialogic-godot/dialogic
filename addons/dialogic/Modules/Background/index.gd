@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [this_folder.path_join('event_background.gd')]

func _get_subsystems() -> Array:
	return [{'name':'Backgrounds', 'script':this_folder.path_join('subsystem_backgrounds.gd')}]


func _get_special_resources() -> Array[Dictionary]:
	return list_special_resources("Transitions/Defaults", "BackgroundTransition", ".gd")
