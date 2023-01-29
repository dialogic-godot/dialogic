extends DialogicIndexer

func _get_layout_scenes() -> Array[Dictionary]:
	return [
		{'name':'Default layout',
		'path':this_folder.path_join('DialogicDefaultScene.tscn'),
		'description':"The default scene. Supports all events+settings."
		},
		{'name':'Example TextBubble layout',
		'path':this_folder.path_join('TextBubble_DialogicScene.tscn'),
		'description':"An example textbubble. Only supports basic text and choice interactions (no music, sounds, portraits, etc.)."
		},
		{'name':'Example RPG layout',
		'path':this_folder.path_join('RPG_DialogicScene.tscn'),
		'description':"An example RPG layout. Comes with only 1 portrait position (intended to be used with RPG-portrait mode)."
		},
	]
