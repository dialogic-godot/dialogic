@tool
extends DialogicIndexer

func _get_settings_pages() -> Array:
	return [this_folder.path_join('settings_converter.tscn')]
