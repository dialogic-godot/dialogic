extends DialogicIndexer

func _get_layout_scenes() -> Array[Dictionary]:
	return [
		{
			'name': 'Visual Novel', 
			'path': this_folder.path_join('/Default/DialogicDefaultLayout.tscn'),
			'author': 'Jowan Spooner',
			'description': "The default scene. Supports all events and settings.",
			'preview_image': [this_folder.path_join('default_layout.png')],
			'folder_to_copy': this_folder.path_join('/Default'), 
		},
		{
			'name': 'Text Bubble',
			'path': this_folder.path_join('TextBubble/DialogicTextBubbleLayout.tscn'),
			'author': 'Jowan Spooner',
			'description': "An example textbubble. Only supports basic text and choice interactions (no portraits, text input, etc.).",
			'preview_image': [this_folder.path_join('textbubble.png')],
			'folder_to_copy': this_folder.path_join('/TextBubble'), 
		},
		{
			'name': 'RPG Single Portrait',
			'path': this_folder.path_join('RPG_BoxPortrait/DialogicRPGLayout.tscn'),
			'author': 'Jowan Spooner',
			'description': "An example RPG layout. Comes with only 1 portrait position (intended to be used with RPG-portrait mode).",
			'preview_image': [this_folder.path_join('rpg_box1.png')],
			'folder_to_copy': this_folder.path_join('/RPG_BoxPortrait'), 
		},
	]
