tool
class_name DialogicResources

## This class is used by the DialogicEditor to access the resources files
## For example by the Editors (Timeline, Character, Theme), the MasterTree and the EventParts

## It is also used by the DialogicUtil class

const RESOURCES_DIR: String = "res://dialogic" # Readonly, used for static data
const WORKING_DIR: String = "user://dialogic" # Readwrite, used for saves


## *****************************************************************************
##							BASIC JSON FUNCTION
## *****************************************************************************
static func load_json(path: String, default: Dictionary={}) -> Dictionary:
	# An easy function to load json files and handle common errors.
	var file := File.new()
	if file.open(path, File.READ) != OK:
		file.close()
		return default
	var data_text: String = file.get_as_text()
	file.close()
	if data_text.empty():
		return default
	var data_parse: JSONParseResult = JSON.parse(data_text)
	if data_parse.error != OK:
		return default
	
	var final_data = data_parse.result
	if typeof(final_data) == TYPE_DICTIONARY:
		return final_data
	
	# If everything else fails
	return default


static func set_json(path: String, data: Dictionary):
	var file = File.new()
	var err = file.open(path, File.WRITE)
	if err == OK:
		file.store_line(JSON.print(data, '\t', true))
		file.close()
	return err


## *****************************************************************************
##							INITIALIZATION
## *****************************************************************************
static func init_dialogic_files() -> void:
	# This functions makes sure that the needed files and folders
	# exists when the plugin is loaded. If they don't, we create 
	# them.
	# WARNING: only call while in the editor
	var directory = Directory.new()
	var paths = get_working_directories()
	var files = get_config_files_paths()
	# Create directories
	for dir in paths:
		if not directory.dir_exists(paths[dir]):
			directory.make_dir_recursive(paths[dir])
			if dir == 'THEME_DIR':
				directory.copy('res://addons/dialogic/Editor/ThemeEditor/default-theme.cfg', str(paths[dir], '/default-theme.cfg'))
	# Create empty files
	for f in files:
		if not directory.file_exists(files[f]):
			create_empty_file(files[f])


static func get_working_directories() -> Dictionary:
	return {
		'RESOURCES_DIR': RESOURCES_DIR,
		'WORKING_DIR': WORKING_DIR,
		'TIMELINE_DIR': RESOURCES_DIR + "/timelines",
		'THEME_DIR': RESOURCES_DIR + "/themes",
		'CHAR_DIR': RESOURCES_DIR + "/characters",
		'CUSTOM_EVENTS_DIR': RESOURCES_DIR + "/custom-events",
		'SOUNDS':RESOURCES_DIR + "/sounds"
	}


static func get_config_files_paths() -> Dictionary:
	return {
		'SETTINGS_FILE': RESOURCES_DIR + "/settings.cfg",
		'DEFAULT_DEFINITIONS_FILE': RESOURCES_DIR + "/definitions.json",
		'FOLDER_STRUCTURE_FILE': RESOURCES_DIR + "/folder_structure.json",
		'DEFINITIONS_DEFAULT_SAVE': WORKING_DIR + "/definitions_default_save.json",
		'STATE_DEFAULT_SAVE': WORKING_DIR + "/state_default_save.json"
	}


## *****************************************************************************
##							BASIC FILE FUNCTION
## *****************************************************************************
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
	# https://docs.godotengine.org/en/stable/classes/class_directory.html#description
	var files: Array = []
	var dir := Directory.new()
	var err = dir.open(path)
	if err == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and not file_name.begins_with("."):
				files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("[Dialogic] Error while accessing path " + path + " - Error: " + str(err))
	return files


static func create_empty_file(path):
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string('')
	file.close()


static func remove_file(path: String):
	var dir = Directory.new()
	var _err = dir.remove(path)
	
	if _err != OK:
		print("[D] There was an error when deleting file at {filepath}. Error: {error}".format(
			{"filepath":path,"error":_err}
		))


static func copy_file(path_from, path_to):
	if (path_from == ''):
		push_error("[Dialogic] Could not copy empty filename")
		return ERR_FILE_BAD_PATH
		
	if (path_to == ''):
		push_error("[Dialogic] Could not copy to empty filename")
		return ERR_FILE_BAD_PATH
	
	var dir = Directory.new()
	if (not dir.file_exists(path_from)):
		push_error("[Dialogic] Could not copy file %s, File does not exists" % [ path_from ])
		return ERR_FILE_NOT_FOUND
		
	if (dir.file_exists(path_to)):
		push_error("[Dialogic] Could not copy file to %s, file already exists" % [ path_to ])
		return ERR_ALREADY_EXISTS
		
	var error = dir.copy(path_from, path_to)
	if (error):
		push_error("[Dialogic] Error while copying %s to %s" % [ path_from, path_to ])
		push_error(error)
		return error
		
	return OK
	pass


## *****************************************************************************
##							CONFIG
## *****************************************************************************
static func get_config(id: String) -> ConfigFile:
	var paths := get_config_files_paths()
	var config := ConfigFile.new()
	if id in paths.keys():
		var err = config.load(paths[id])
		if err != OK:
			print("[Dialogic] Error while opening config file " + paths[id] + ". Error: " + str(err))
	return config


## *****************************************************************************
##							TIMELINES
## *****************************************************************************
# Can only be edited in the editor

static func get_timeline_json(path: String):
	return load_json(get_path('TIMELINE_DIR', path))


static func set_timeline(timeline: Dictionary):
	# WARNING: For use in the editor only
	set_json(get_path('TIMELINE_DIR', timeline['metadata']['file']), timeline)


static func delete_timeline(filename: String):
	# WARNING: For use in the editor only
	remove_file(get_path('TIMELINE_DIR', filename))


## *****************************************************************************
##							CHARACTERS
## *****************************************************************************
# Can only be edited in the editor

static func get_character_json(path: String):
	return load_json(get_path('CHAR_DIR', path))


static func set_character(character: Dictionary):
	# WARNING: For use in the editor only
	set_json(get_path('CHAR_DIR', character['id']), character)


static func delete_character(filename: String):
	# WARNING: For use in the editor only
	remove_file(get_path('CHAR_DIR', filename))


## *****************************************************************************
##							THEMES
## *****************************************************************************
# Can only be edited in the editor

static func get_theme_config(filename: String):
	var config = ConfigFile.new()
	var path
	if filename.begins_with('res://'):
		path = filename
	else:
		path = get_path('THEME_DIR', filename)
	var err = config.load(path)
	if err == OK:
		return config


static func set_theme_value(filename:String, section:String, key:String, value):
	# WARNING: For use in the editor only
	var config = get_theme_config(filename)
	config.set_value(section, key, value)
	config.save(get_path('THEME_DIR', filename))


static func add_theme(filename: String):
	create_empty_file(get_path('THEME_DIR', filename))


static func delete_theme(filename: String):
	remove_file(get_path('THEME_DIR', filename))
	
	
static func duplicate_theme(from_filename: String, to_filename: String):
	copy_file(get_path('THEME_DIR', from_filename), get_path('THEME_DIR', to_filename))

## *****************************************************************************
##							SETTINGS
## *****************************************************************************
# Can only be edited in the editor


static func get_settings_config() -> ConfigFile:
	return get_config("SETTINGS_FILE")


static func set_settings_value(section: String, key: String, value):
	var config = get_settings_config()
	config.set_value(section, key, value)
	config.save(get_config_files_paths()['SETTINGS_FILE'])

static func get_settings_value(section:String, key: String, default):
	var config = get_settings_config()
	return config.get_value(section, key, default)


## *****************************************************************************
##						DEFAULT DEFINITIONS
## *****************************************************************************
# Can only be edited in the editor


static func get_default_definitions() -> Dictionary:
	return load_json(get_config_files_paths()['DEFAULT_DEFINITIONS_FILE'], {'variables': [], 'glossary': []})


static func save_default_definitions(data: Dictionary):
	set_json(get_config_files_paths()['DEFAULT_DEFINITIONS_FILE'], data)


static func get_default_definition_item(id: String):
	var data = get_default_definitions()
	return DialogicDefinitionsUtil.get_definition_by_id(data, id)


static func set_default_definition_variable(id: String, name: String, value):
	# WARNING: For use in the editor only
	var data = get_default_definitions()
	DialogicDefinitionsUtil.set_definition_variable(data, id, name, value)
	save_default_definitions(data)


static func set_default_definition_glossary(id: String, name: String, extra_title: String,  extra_text: String,  extra_extra: String):
	# WARNING: For use in the editor only
	var data = get_default_definitions()
	DialogicDefinitionsUtil.set_definition_glossary(data, id, name, extra_title, extra_text, extra_extra)
	save_default_definitions(data)


static func delete_default_definition(id: String):
	# WARNING: For use in the editor only
	var data = get_default_definitions()
	DialogicDefinitionsUtil.delete_definition(data, id)
	save_default_definitions(data)



## *****************************************************************************
##						SAVES DURING GAME
## *****************************************************************************
# Folders in the user://dialogic directory function as save_slots.

# retruns a list of all save folders. 
# -> this returns a list of the save_slot-names
static func get_saves_folders() -> Array:
	var save_folders = []
	var directory := Directory.new()
	if directory.open(WORKING_DIR) != OK:
		print("[D] Error: Failed to access working directory.")
		return []
	
	directory.list_dir_begin()
	var file_name = directory.get_next()
	while file_name != "":
		if directory.current_is_dir() and not file_name.begins_with("."):
			save_folders.append(file_name)
		file_name = directory.get_next()

	return save_folders

# this adds a new save folder with the given name
static func add_save_folder(save_name: String) -> void:
	var directory := Directory.new()
	if directory.open(WORKING_DIR) != OK:
		print("[D] Error: Failed to access working directory.")
		return 
	directory.make_dir(save_name)
	
	var file := File.new()
	if file.open(WORKING_DIR+"/"+save_name+"/definitions.json", File.WRITE) == OK:
		file.store_string('')
		file.close()
	if file.open(WORKING_DIR+"/"+save_name+"/state.json", File.WRITE) == OK:
		file.store_string('')
		file.close()

# this removes the given  folder
static func remove_save_folder(save_name: String) -> void:
	var directory := Directory.new()
	if directory.open(WORKING_DIR+"/"+save_name) != OK:
		print("[D] Error: Failed to access save folder '"+save_name+"'.")
		return
	
	directory.list_dir_begin()
	var file_name = directory.get_next()
	while file_name != "":
		directory.remove(file_name)
		file_name = directory.get_next()
	directory.remove(WORKING_DIR+"/"+save_name)

# reset the definitions and state of the given save folder (or default)
static func reset_save(save_name: String = '') -> void:
	save_state_info(save_name, {})
	save_definitions(save_name, get_default_definitions())

# saves the state_info into the state.json file in the save folder "save_name"
static func save_state_info(save_name: String, state_info: Dictionary) -> void:
	if save_name == '':
		set_json(get_config_files_paths()['STATE_DEFAULT_SAVE'], state_info)
		return
	
	if not save_name in get_saves_folders():
		add_save_folder(save_name)
	
	set_json(WORKING_DIR+"/"+save_name+"/state.json", state_info)

# return the state_info from the state.json file in the save folder "save_name"
static func get_saved_state_info(save_name: String) -> Dictionary:
	if save_name == '':
		return load_json(get_config_files_paths()['STATE_DEFAULT_SAVE'], {})
	
	if not save_name in get_saves_folders():
		return {}
	
	return load_json(WORKING_DIR+"/"+save_name+"/state.json", {})

# saves the given definitions into the definitions.json file in the save folder "save name"
static func save_definitions(save_name: String, definitions_info: Dictionary) -> void:
	if save_name == "":
		set_json(get_config_files_paths()['DEFINITIONS_DEFAULT_SAVE'], definitions_info)
		return
	
	if not save_name in get_saves_folders():
		add_save_folder(save_name)
	
	set_json(WORKING_DIR+"/"+save_name+"/definitions.json", definitions_info)

# return the definition info from the definiiotn.json in the save folder "save name"
static func get_saved_definitions(save_name: String = '') -> Dictionary:
	if save_name == '':
		return load_json(get_config_files_paths()['DEFINITIONS_DEFAULT_SAVE'], get_default_definitions())
	
	if not save_name in get_saves_folders():
		print("[D] Wasn't able to find save '"+save_name+"'. Loaded the default definitions.")
		return get_default_definitions()
	
	return load_json(WORKING_DIR+"/"+save_name+"/definitions.json", {})



## *****************************************************************************
##						FOLDER STRUCTURE
## *****************************************************************************
# The DialogicEditor uses a fake folder structure
# Can only be edited in the editor

static func get_resource_folder_structure() -> Dictionary:
	return load_json(get_config_files_paths()['FOLDER_STRUCTURE_FILE'], 
		{"folders":
			{"Timelines":
				{
					"folders":{},
					"files":[],
					'metadata':{'color':null, 'folded':false}
				},
			"Characters":
				{
					"folders":{},
					"files":[],
					'metadata':{'color':null, 'folded':false}
				},
			"Definitions":
				{
					"folders":{},
					"files":[],
					'metadata':{'color':null, 'folded':false}
				},
			"Themes":
				{
					"folders":{},
					"files":[],
					'metadata':{'color':null, 'folded':false}
				},
			}, 
		"files":[]
		})

static func save_resource_folder_structure(data):
	set_json(get_config_files_paths()['FOLDER_STRUCTURE_FILE'], data)
