@tool
extends DialogicIndexer


func _get_events() -> Array:
	return [this_folder.path_join('event_jump.gd'), this_folder.path_join('event_label.gd')]
