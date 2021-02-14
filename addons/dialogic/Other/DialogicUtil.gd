tool
class_name DialogicUtil

enum {GLOSSARY_NONE, GLOSSARY_EXTRA, GLOSSARY_NUMBER, GLOSSARY_STRING}

static func init_dialogic_files() -> void:
	# This functions makes sure that the needed files and folders
	# exists when the plugin is loaded. If they don't, we create 
	# them.
	var directory = Directory.new();
	var paths = get_working_directories()
	for dir in paths:
		if 'settings.json' in paths[dir]:
			update_setting()
		elif 'glossary.json' in paths[dir]:
			load_glossary()
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
	return data_parse.result


static func load_settings() -> Dictionary:
	# This functions tries to load the settings. If it fails, it will
	# generate the default values and save them so we have a file to
	# work with and avoid future error messages.
	var defaults = default_settings()
	var directory = Directory.new();
	if directory.file_exists(get_path('SETTINGS_FILE')):
		var settings: Dictionary = load_json(get_path('SETTINGS_FILE'))
		for x in defaults:
			if settings.has(x) == false:
				settings[x] = defaults[x]
		if settings.has('error'):
			settings = {}
		return settings
	else:
		return defaults


static func save_glossary(glossary) -> void:
	var file:File = File.new()
	file.open(get_path('GLOSSARY_FILE'), File.WRITE)
	file.store_line(to_json(glossary))
	file.close()


static func update_setting(key: String = '', value = '') -> void:
	# This function will open the settings file and update one of the values
	var data = load_settings()
	if key != '':
		data[key] = value
	
	var file:File = File.new()
	file.open(get_path('SETTINGS_FILE'), File.WRITE)
	file.store_line(to_json(data))
	file.close()


static func get_working_directories() -> Dictionary:
	var WORKING_DIR: String = "res://dialogic"
	var paths: Dictionary = {
		'WORKING_DIR': WORKING_DIR,
		'TIMELINE_DIR': WORKING_DIR + "/timelines",
		'CHAR_DIR': WORKING_DIR + "/characters",
		'SETTINGS_FILE': WORKING_DIR + "/settings.json",
		'GLOSSARY_FILE': WORKING_DIR + "/glossary.json",
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
				'display_name': display_name
			})

	return characters


static func get_timeline_list() -> Array:
	var timelines: Array = []
	for file in listdir(get_path('TIMELINE_DIR')):
		if '.json' in file:
			var data = load_json(get_path('TIMELINE_DIR', file))
			var metadata = data['metadata']
			var color = Color("#ffffff")
			if metadata.has('name'):
				timelines.append({'name':metadata['name'], 'color': color, 'file': file })
			else:
				timelines.append({'name':file.split('.')[0], 'color': color, 'file': file })
	return timelines


static func load_glossary() -> Dictionary:
	var directory = Directory.new();
	if directory.file_exists(get_path('GLOSSARY_FILE')):
		var glossary: Dictionary = load_json(get_path('GLOSSARY_FILE'))
		if glossary.has('error'):
			glossary = {}
		return glossary
	else:
		var file:File = File.new()
		file.open(get_path('GLOSSARY_FILE'), File.WRITE)
		file.store_line(to_json({}))
		file.close()
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


static func default_settings():
	var ds = {
		"background_texture_button_visible": true,
		"button_background": "#ff000000",
		"button_background_visible": false,
		"button_image": "res://addons/dialogic/Images/background/background-2.png",
		"button_image_visible": true,
		"button_offset_x": 5,
		"button_offset_y": 5,
		"button_separation": 5,
		"button_text_color": "#ffffffff",
		"button_text_color_enabled": true,
		
		"theme_action_key": "ui_accept",
		"theme_background_color": "#ff000000",
		"theme_background_color_visible": false,
		"theme_background_image": "res://addons/dialogic/Images/background/background-2.png",
		"theme_font": "res://addons/dialogic/Fonts/DefaultFont.tres",
		"theme_next_image": "res://addons/dialogic/Images/next-indicator.png",
		"theme_shadow_offset_x": 2,
		"theme_shadow_offset_y": 2,
		"theme_text_color": "#ffffffff",
		"theme_text_margin": 10,
		"theme_text_margin_h": 20,
		"theme_text_shadow": false,
		"theme_text_shadow_color": "#9e000000",
		"theme_text_speed": 2,
		
		"glossary_font": "res://addons/dialogic/Fonts/GlossaryFont.tres",
		"glossary_color": "#ffffffff",
	}
	return ds


static func generate_random_id() -> String:
	return str(OS.get_unix_time()) + '-' + str(100 + randi()%899+1)


static func compare_dicts(dict_1: Dictionary, dict_2: Dictionary) -> bool:
	# I tried using the .hash() function but it was returning different numbers
	# even when the dictionary was exactly the same.
	if str(dict_1) != "Null" and str(dict_2) != "Null":
		if str(dict_1) == str(dict_2):
			return true
	return false
