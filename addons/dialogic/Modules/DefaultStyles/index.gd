extends DialogicIndexer

func _get_layout_scenes() -> Array[Dictionary]:
	return scan_for_layouts()
