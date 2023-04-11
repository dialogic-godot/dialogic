extends DialogicIndexer

func _get_layout_scenes() -> Array[Dictionary]:
	return [
		{'name':'Default', 
		'path':this_folder.path_join('/Default/DialogicDefaultLayout.tscn'),
		'description':"The default scene. Supports all events and settings.",
		'preview_image' :[this_folder.path_join('default_layout.png')],
		'folder_to_copy': this_folder.path_join('/Default'), 
		},
		{'name':'TextBubble',
		'path':this_folder.path_join('TextBubble/DialogicTextBubbleLayout.tscn'),
		'description':"An example textbubble. Only supports basic text and choice interactions (no portraits, text input, etc.).",
		'preview_image' :[this_folder.path_join('textbubble.png')],
		'folder_to_copy': this_folder.path_join('/TextBubble'), 
		},
		{'name':'RPG One Portrait',
		'path':this_folder.path_join('RPG_BoxPortrait/DialogicRPGLayout.tscn'),
		'description':"An example RPG layout. Comes with only 1 portrait position (intended to be used with RPG-portrait mode).",
		'preview_image' :[this_folder.path_join('rpg_box1.png')],
		'folder_to_copy': this_folder.path_join('/RPG_BoxPortrait'), 
		},
	]
