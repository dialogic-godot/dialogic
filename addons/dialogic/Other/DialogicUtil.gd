tool
class_name DialogicUtil

enum {GLOSSARY_NONE, GLOSSARY_EXTRA, GLOSSARY_NUMBER, GLOSSARY_STRING}

# This class was initially for doing small things... but after a while
# it ended up being one of the corner stones of the plugin. 
# It should probably be split into several other classes and leave 
# just the basic stuff here, but I'll keep working like this until I have
# some extra time to burn. 
# A good point to start would be to add a "resource manager" instead of
# handling most of that here. But who knows? (:

static func init_dialogic_files() -> void:
	# This functions makes sure that the needed files and folders
	# exists when the plugin is loaded. If they don't, we create 
	# them.
	var directory = Directory.new()
	var paths = get_working_directories()
	for dir in paths:
		if 'settings.cfg' in paths[dir]:
			if directory.file_exists(paths['SETTINGS_FILE']) == false:
				create_empty_file(paths['SETTINGS_FILE'])
		elif 'definitions.cfg' in paths[dir]:
			if directory.file_exists(paths['DEFINITIONS_FILE']) == false:
				create_empty_file(paths['DEFINITIONS_FILE'])
		else:
			if directory.dir_exists(paths[dir]) == false:
				directory.make_dir(paths[dir])


static func load_json(path: String) -> Dictionary:
	# An easy function to load json files and handle common errors.
	var file:File = File.new()
	if file.open(path, File.READ) != OK:
		file.close()
		return {'error':'file read error'}
	var data_text: String = file.get_as_text()
	file.close()
	var data_parse:JSONParseResult = JSON.parse(data_text)
	if data_parse.error != OK:
		return {'error':'data parse error'}

	var final_data = data_parse.result
	if typeof(final_data) == TYPE_DICTIONARY:
		return final_data
	
	# If everything else fails
	return {'error':'data parse error'}


static func get_working_directories() -> Dictionary:
	var WORKING_DIR: String = "res://dialogic"
	var paths: Dictionary = {
		'WORKING_DIR': WORKING_DIR,
		'TIMELINE_DIR': WORKING_DIR + "/timelines",
		'THEME_DIR': WORKING_DIR + "/themes",
		'CHAR_DIR': WORKING_DIR + "/characters",
		'DEFINITIONS_FILE': WORKING_DIR + "/definitions.cfg",
		'SETTINGS_FILE': WORKING_DIR + "/settings.cfg",
	}
	return paths


static func get_path(name: String, extra: String ='') -> String:
	var paths: Dictionary = get_working_directories()
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
				color = Color(data['color'])
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
				'display_name': display_name,
				'data': data # This should be the only thing passed... not sure what I was thinking
			})

	return characters


static func get_timeline_list() -> Array:
	var timelines: Array = []
	for file in listdir(get_path('TIMELINE_DIR')):
		if '.json' in file:
			var data = load_json(get_path('TIMELINE_DIR', file))
			if data.has('error') == false:
				var metadata = data['metadata']
				var color = Color("#ffffff")
				if metadata.has('name'):
					timelines.append({'name':metadata['name'], 'color': color, 'file': file })
				else:
					timelines.append({'name':file.split('.')[0], 'color': color, 'file': file })
	return timelines


static func get_definition_list() -> Array:
	var definitions: Array = []
	var config = ConfigFile.new()
	var err = config.load(get_path('DEFINITIONS_FILE'))
	if err == OK:
		for section in config.get_sections():
			definitions.append({
				'section': section,
				'name': config.get_value(section, 'name', section),
				'config': config,
				'type': config.get_value(section, 'type', 0),
			})
	return definitions


static func load_glossary() -> Dictionary:
	return {}


static func get_var(variable: String):
	var glossary = load_glossary()
	for g in glossary:
		var current = glossary[g]
		if current['name'] == variable:
			if current['type'] == GLOSSARY_NUMBER:
				if '.' in current['number']:
					return float(current['number'])
				else:
					return int(current['number'])
			return current
	
	return {}


static func set_var_by_id(id, value, glossary):
	#var glossary = load_glossary()
	var _id = id.replace('.json', '')
	if glossary[_id]['type'] == GLOSSARY_NUMBER:
		glossary[_id]['number'] = value
	if glossary[_id]['type'] == GLOSSARY_STRING:
		glossary[_id]['string'] = value
	return glossary


static func get_glossary_by_file(filename) -> Dictionary:
	var glossary = load_glossary()
	for g in glossary:
		if glossary[g]['file'] == filename:
			return glossary[g]
	
	return {}


static func generate_random_id() -> String:
	return str(OS.get_unix_time()) + '-' + str(100 + randi()%899+1)


static func compare_dicts(dict_1: Dictionary, dict_2: Dictionary) -> bool:
	# I tried using the .hash() function but it was returning different numbers
	# even when the dictionary was exactly the same.
	if str(dict_1) != "Null" and str(dict_2) != "Null":
		if str(dict_1) == str(dict_2):
			return true
	return false


static func get_theme_list() -> Array:
	var themes: Array = []
	for file in listdir(get_path('THEME_DIR')):
		if '.cfg' in file:
			var config = ConfigFile.new()
			var err = config.load(get_path('THEME_DIR', file))
			if err == OK: # If not, something went wrong with the file loading
				themes.append({
					'file': file,
					'name': config.get_value('settings','name', file),
					'config': config
				})
			else:
				print('Error loading ',file , ' - Error: ', err)
	return themes


static func get_theme(filename):
	var config = ConfigFile.new()
	var err = config.load(get_path('THEME_DIR', filename))
	if err == OK:
		return config
	#else:
	#	return AQUI EL DEFAULT THEME


static func set_theme_value(filename, section, key, value):
	var config = ConfigFile.new()
	var file = get_path('THEME_DIR', filename)
	var err = config.load(file)
	if err == OK:
		config.set_value(section, key, value)
		config.save(file)


static func create_empty_file(path):
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string('')
	file.close()


static func get_settings():
	var config = ConfigFile.new()
	var err = config.load(get_path('SETTINGS_FILE'))
	if err == OK:
		return config
	else:
		print('Error loading ', get_path('SETTINGS_FILE'), '. Was it modified manually? Make sure it exists!')
