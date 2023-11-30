extends DialogicIndexer

func _get_editors() -> Array:
	return [this_folder.path_join('style_editor.tscn')]
