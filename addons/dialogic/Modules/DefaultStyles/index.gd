extends DialogicIndexer

func _get_layout_scenes() -> Array:
	return scan_styles("res://addons/dialogic/Modules/DefaultStyles/")


func scan_styles(path) -> Array:
	var dir := DirAccess.open(path)
	var style_list := []
	if dir:
		dir.list_dir_begin()
		var dir_name := dir.get_next()
		while dir_name != "":
			if dir.current_is_dir():
				if dir.file_exists(dir_name.path_join('style.cfg')):
					var config := ConfigFile.new()
					var config_path: String = path.path_join(dir_name).path_join('style.cfg')
					var default_image_path: String = path.path_join(dir_name).path_join('preview.png')
					config.load(config_path)
					style_list.append(
						{
							'name': config.get_value('style', 'name', 'Unnamed Layout'),
							'path': path.path_join(dir_name).path_join(config.get_value('style', 'scene')),
							'author': config.get_value('style', 'author', 'Anonymous'),
							'description': config.get_value('style', 'descriptin', 'No description'),
							'preview_image': [config.get_value('style', 'image', default_image_path)]
						}
					)
			dir_name = dir.get_next()
	return style_list
