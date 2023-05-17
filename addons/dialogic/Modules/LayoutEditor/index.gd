extends DialogicIndexer

func _get_editors() -> Array:
	return [this_folder.path_join('layout_editor.tscn')]
