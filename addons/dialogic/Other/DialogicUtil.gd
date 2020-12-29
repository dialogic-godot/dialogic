tool
class_name DialogicUtil


static func load_json(path: String) -> Dictionary:
	var file:File = File.new()
	if file.open(path, File.READ) != OK:
		file.close()
		return {'error':'file read error'}
	var data_text: String = file.get_as_text()
	file.close()
	var data_parse:JSONParseResult = JSON.parse(data_text)
	if data_parse.error != OK:
		return {'error':'data parse error'}
	return data_parse.result


static func load_settings() -> Dictionary:
	var settings: Dictionary = load_json(get_path('SETTINGS_FILE'))
	if settings.has('error'):
		settings = {}
		print('[!] settings loaded: ' + str(settings))
	return settings


static func update_setting(key: String, value) -> void:
	var data = load_settings()
	data[key] = value
	
	var file:File = File.new()
	file.open(get_path('SETTINGS_FILE'), File.WRITE)
	file.store_line(to_json(data))
	file.close()


static func get_path(name: String, extra: String ='') -> String:
	var WORKING_DIR: String = "res://dialogic"
	var paths: Dictionary = {
		'WORKING_DIR': WORKING_DIR,
		'TIMELINE_DIR': WORKING_DIR + "/dialogs",
		'CHAR_DIR': WORKING_DIR + "/characters",
		'SETTINGS_FILE': WORKING_DIR + "/settings.json",
	}
	if extra != '':
		return paths[name] + '/' + extra
	else:
		return paths[name]


static func get_filename_from_path(path: String, extension = false) -> String:
	var file_name: String = path.split('/')[-1]
	if extension == false:
		file_name = file_name.split('.')[0]
	return file_name


static func listdir(path: String) -> Array:
	# https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
	var files: Array = []
	var dir: Directory = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)
	dir.list_dir_end()
	return files


static func get_character_list() -> Array:
	var characters: Array = []
	for file in listdir(get_path('CHAR_DIR')):
		if '.json' in file:
			var data: Dictionary     = load_json(get_path('CHAR_DIR', file))
			var color: Color         = Color("#ffffff")
			var c_name: String       = data['id']
			var default_speaker      = false
			var portraits: Array     = []
			var display_name: String = ''
			
			if data.has('color'):
				color = Color('#' + data['color'])
			if data.has('name'):
				c_name = data['name']
			if data.has('default_speaker'):
				default_speaker = data['default_speaker']
			if data.has('portraits'):
				portraits = data['portraits']
			if data.has('display_name'):
				if data['display_name_bool']:
					if data.has('display_name'):
						display_name = data['display_name']
						
			characters.append({
				'name': c_name,
				'color': color,
				'file': file,
				'default_speaker' : default_speaker,
				'portraits': portraits,
				'display_name': display_name
			})

	return characters
