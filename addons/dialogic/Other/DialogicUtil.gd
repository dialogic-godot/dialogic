tool
class_name DialogicUtil

## This class is used by the DialogicEditor
## For example by the Editors (Timeline, Character, Theme), the MasterTree and the EventParts

static func list_to_dict(list):
	var dict := {}
	for val in list:
		dict[val["file"]] = val
	return dict

## *****************************************************************************
##								CHARACTERS
## *****************************************************************************

static func get_character_list() -> Array:
	var characters: Array = []
	for file in DialogicResources.listdir(DialogicResources.get_path('CHAR_DIR')):
		if '.json' in file:
			var data: Dictionary = DialogicResources.get_character_json(file)
			
			characters.append({
				'name': data.get('name', data['id']),
				'color': Color(data.get('color', "#ffffff")),
				'file': file,
				'portraits': data.get('portraits', []),
				'display_name': data.get('display_name', ''),
				'nickname': data.get('nickname', ''),
				'data': data # This should be the only thing passed... not sure what I was thinking
			})
	return characters



static func get_characters_dict():
	return list_to_dict(get_character_list())


static func get_sorted_character_list():
	var array = get_character_list()
	array.sort_custom(DialgicSorter, 'sort_resources')
	return array


# helper that allows to get a character by file
static func get_character(character_id):
	var characters = get_character_list()
	for c in characters:
		if c['file'] == character_id:
			return c
	return {}

## *****************************************************************************
##								TIMELINES
## *****************************************************************************


static func get_timeline_list() -> Array:
	var timelines: Array = []
	for file in DialogicResources.listdir(DialogicResources.get_path('TIMELINE_DIR')):
		if '.json' in file: # TODO check for real .json because if .json is in the middle of the sentence it still thinks it is a timeline
			var data = DialogicResources.get_timeline_json(file)
			if data.has('error') == false:
				if data.has('metadata'):
					var metadata = data['metadata']
					var color = Color("#ffffff")
					if metadata.has('name'):
						timelines.append({'name':metadata['name'], 'color': color, 'file': file })
					else:
						timelines.append({'name':file.split('.')[0], 'color': color, 'file': file })
	return timelines

# returns a dictionary with file_names as keys and metadata as values
static func get_timeline_dict() -> Dictionary:
	return list_to_dict(get_timeline_list())


static func get_sorted_timeline_list():
	var array = get_timeline_list()
	array.sort_custom(DialgicSorter, 'sort_resources')
	return array


## *****************************************************************************
##								THEMES
## *****************************************************************************

static func get_theme_list() -> Array:
	var themes: Array = []
	for file in DialogicResources.listdir(DialogicResources.get_path('THEME_DIR')):
		if '.cfg' in file:
			var config = DialogicResources.get_theme_config(file)
			themes.append({
				'file': file,
				'name': config.get_value('settings','name', file),
				'config': config
			})
	return themes

# returns a dictionary with file_names as keys and metadata as values
static func get_theme_dict() -> Dictionary:
	return list_to_dict(get_theme_list())


static func get_sorted_theme_list():
	var array = get_theme_list()
	array.sort_custom(DialgicSorter, 'sort_resources')
	return array


## *****************************************************************************
##								DEFINITIONS
## *****************************************************************************

static func get_default_definitions_list() -> Array:
	return DialogicDefinitionsUtil.definitions_json_to_array(DialogicResources.get_default_definitions())


static func get_default_definitions_dict():
	var dict = {}
	for val in get_default_definitions_list():
		dict[val['id']] = val
	return dict


static func get_sorted_default_definitions_list():
	var array = get_default_definitions_list()
	array.sort_custom(DialgicSorter, 'sort_resources')
	return array

# returns the result of the given dialogic comparison
static func compare_definitions(def_value: String, event_value: String, condition: String):
	var definitions
	if not Engine.is_editor_hint():
		if Engine.get_main_loop().has_meta('definitions'):
			definitions = Engine.get_main_loop().get_meta('definitions')
		else:
			definitions = DialogicResources.get_default_definitions()
			Engine.get_main_loop().set_meta('definitions', definitions)
	else:
		definitions = DialogicResources.get_default_definitions()
	var condition_met = false
	if def_value != null and event_value != null:
		# check if event_value equals a definition name and use that instead
		for d in definitions['variables']:
			if (d['name'] != '' and d['name'] == event_value):
				event_value = d['value']
				break;
		var converted_def_value = def_value
		var converted_event_value = event_value
		if def_value.is_valid_float() and event_value.is_valid_float():
			converted_def_value = float(def_value)
			converted_event_value = float(event_value)
		if condition == '':
			condition = '==' # The default condition is Equal to
		match condition:
			"==":
				condition_met = converted_def_value == converted_event_value
			"!=":
				condition_met = converted_def_value != converted_event_value
			">":
				condition_met = converted_def_value > converted_event_value
			">=":
				condition_met = converted_def_value >= converted_event_value
			"<":
				condition_met = converted_def_value < converted_event_value
			"<=":
				condition_met = converted_def_value <= converted_event_value
	return condition_met


## *****************************************************************************
##							RESOURCE FOLDER MANAGEMENT
## *****************************************************************************
# The MasterTree uses a "fake" folder structure

## PATH FUNCTIONS
# removes the last thing from a path
static func get_parent_path(path: String):
	return path.replace("/"+path.split("/")[-1], "")


## GETTERS
# returns the full resource structure
static func get_full_resource_folder_structure():
	return DialogicResources.get_resource_folder_structure()

static func get_timelines_folder_structure():
	return get_folder_at_path("Timelines")

static func get_characters_folder_structure():
	return get_folder_at_path("Characters")
	
static func get_definitions_folder_structure():
	return get_folder_at_path("Definitions")
	
static func get_theme_folder_structure():
	return get_folder_at_path("Themes")

# this gets the content of the folder at a path
# a path consists of the foldernames divided by '/'
static func get_folder_at_path(path):
	var folder_data = get_full_resource_folder_structure()
	
	for folder in path.split("/"):
		if folder:
			folder_data = folder_data['folders'][folder]
	
	if folder_data == null:
		folder_data = {"folders":{}, "files":[]}
	return folder_data



## FOLDER METADATA
static func set_folder_meta(flat_structure:Dictionary, item: Dictionary, key:String, value):
	if 'category' in item:
		if flat_structure[item['category'] + "_Array"][item['step']]['value'][key] != value:
			flat_structure[item['category'] + "_Array"][item['step']]['value'][key] = value
			
			flat_structure = editor_array_to_flat_structure(flat_structure,item['category'])
			DialogicResources.save_resource_folder_flat_structure(flat_structure)

static func get_folder_meta(folder_path: String, key:String):
	return get_folder_at_path(folder_path)['metadata'][key]


## FOLDER FUNCTIONS
static func add_folder(flat_structure:Dictionary, tree:String, path:Dictionary, folder_name:String):
	#first find the parent folder from here
	# check if the name is allowed
	var new_path = path['path'] + path['name'] + "/" + folder_name + "/."
	if new_path in flat_structure[tree]:
		print("[D] A folder with the name '"+folder_name+"' already exists in the target folder '"+path['path']+"'.")
		return ERR_ALREADY_EXISTS
	
	flat_structure[tree + "_Array"].insert(path['step'] + 1, {'key': new_path, "value":{'color':null, 'folded':false}})
	flat_structure = editor_array_to_flat_structure(flat_structure,tree)
	
	DialogicResources.save_resource_folder_flat_structure(flat_structure)
	return OK

static func remove_folder(flat_structure: Dictionary, tree:String, folder_data:Dictionary, delete_files:bool = true):
	flat_structure[tree +"_Array"].remove(folder_data['step'])
	
	if delete_files:
		var folder_root = folder_data['path'] + "/" + folder_data['name'] + "/" 
		
		var new_array = []
		
		for idx in flat_structure[tree +"_Array"].size():
			if not folder_root in flat_structure[tree +"_Array"][idx]['key']:
				new_array.push_back(flat_structure[tree +"_Array"][idx])
				
		flat_structure[tree +"_Array"] = new_array	
	
	flat_structure = editor_array_to_flat_structure(flat_structure, tree)

		
	DialogicResources.save_resource_folder_flat_structure(flat_structure)

static func rename_folder(flat_structure: Dictionary, tree:String, path:Dictionary, new_folder_name:String):
	#forward slashes are disallowed in names, we will replace them with a hyphen
	new_folder_name = new_folder_name.replace("/", "-")
	
	# check if the name is allowed
	var new_path = path['path']  + new_folder_name + "/."
	
	if new_path in flat_structure[tree]:
		print("[D] A folder with the name '"+new_folder_name+"' already exists in the target folder '"++path['path']+"'.")
		return ERR_ALREADY_EXISTS
	elif new_folder_name.empty():
		return ERR_PRINTER_ON_FIRE
		
	var old_path = flat_structure[tree + "_Array"][path['step']]['key'].rstrip(".")
	flat_structure[tree + "_Array"][path['step']]['key'] = new_path
	
	for idx in flat_structure[tree + "_Array"].size():
		flat_structure[tree + "_Array"][idx]['key'] = flat_structure[tree + "_Array"][idx]['key'].replace(old_path, new_path.rstrip("."))
	
	
	flat_structure = editor_array_to_flat_structure(flat_structure, tree)
	
	DialogicResources.save_resource_folder_flat_structure(flat_structure)

	return OK

static func move_folder_to_folder(flat_structure:Dictionary, tree:String, original_data:Dictionary, destination_data:Dictionary, drop_position = 0):
	#itll trigger if you decide not to move a folder
	if original_data['original_step'] == destination_data['step']:
		return OK
	
	#abort if its trying to move folder to wrong tree
	if original_data['category'] != destination_data['category']:
		return ERR_INVALID_DATA

	var original_position = original_data['original_step']
	var insert_position = destination_data['step']
	#adjust for the drop position
	if 	drop_position != -1:
		insert_position = insert_position + 1	
	
	# check if the name is allowed
	var new_path = destination_data['path']
	
	if new_path in flat_structure[tree]:
		print("[D] A folder with the name '"+destination_data['path'].split("/")[-1]+"' already exists in the target folder '"+original_data['path']+"'.")
		return ERR_ALREADY_EXISTS

	
	# remove the old folder BUT DON'T DELETE THE FILES!!!!!!!!!!!
	# took me ages to find this when I forgot it..
	
	var new_array=[]
	var rename_array = []
	
	#where we drop it will depend on the position. if we're targeting either above or below, we want to put it at the same level, not subfolder
	var original_folder = ""
	var replace_folder = ""
	if drop_position != -1:
		original_folder = original_data['orig_path'] + original_data['name'] + '/'
		replace_folder = destination_data['path'] + destination_data['name'] + '/' + original_data['name'] + '/'
	else: 
		original_folder = original_data['orig_path'] + original_data['name'] + '/'
		replace_folder = destination_data['path'] + original_data['name'] + '/'
	
	
	#first iterate through and find all the items that need to be renamed
	for idx in flat_structure[tree +"_Array"].size():
		if original_folder in flat_structure[tree +"_Array"][idx]['key']:
			var item = flat_structure[tree +"_Array"][idx].duplicate()
			item['key'] = item['key'].replace(original_folder, replace_folder)
			if 'path' in item['value']:
				item['value']['path'] = item['value']['path'].replace(original_folder, replace_folder)
			rename_array.append(item)
		else:
			new_array.append(flat_structure[tree +"_Array"][idx])
			
	if (original_position < insert_position):
		insert_position = insert_position - rename_array.size()
			
	#now merge in and replace the original ones		
	while rename_array.size() > 0:
			new_array.insert(insert_position, rename_array.pop_back())
	
	#return ERR_INVALID_DATA
	
	flat_structure[tree +"_Array"] = new_array	
	
	flat_structure = editor_array_to_flat_structure(flat_structure, tree)
	
	DialogicResources.save_resource_folder_flat_structure(flat_structure)
	
	return OK

## FILE FUNCTIONS
static func move_file_to_folder(flat_structure:Dictionary, tree:String, original_data:Dictionary, destination_data:Dictionary, drop_position = 0):
	#abort if its trying to move folder to wrong tree
	if original_data['category'] != destination_data['category']:
		return ERR_INVALID_DATA

	var insert_position = destination_data['step']
	#adjust for the drop position
	if drop_position != -1:
		insert_position = insert_position + 1
	
	#check to make sure the next item is a file, because if not we need to roll down to the next file at the same level
	if 'folded' in flat_structure[tree +"_Array"][destination_data['step']]['value']:
		var destination_folder = ""
		if drop_position == -1:
			destination_folder = destination_data['path']
		else:
			destination_folder = destination_data['path'] + destination_data['name'] + "/"
		
		#var destination_path = 
		var searching = true
		#print(flat_structure[tree +"_Array"])
		while searching:
			insert_position = insert_position + 1
			if 'folded' in flat_structure[tree +"_Array"][insert_position]['value']:
				if ! destination_folder in flat_structure[tree +"_Array"][insert_position]['key']:
					searching = false
			else: 
				if flat_structure[tree +"_Array"][insert_position]['value']['path'] == destination_folder: 
					searching = false
			continue
				#if flat_structure[tree +"_Array"][insert_position]['key']:
					#flat_structure[tree +"_Array"][insert_position]['value']['path'] != destination_data['path'] + destination_data['folder'] + "/"
					

	#if the file came from before where we are moving it to, we need to decrease the position since orders being changed
	if original_data['original_step'] < destination_data['step']:
		insert_position = insert_position - 1
		
	
	var moving = flat_structure[tree +"_Array"].pop_at(original_data['original_step'])
	
	if destination_data['editortype'] == "folder":
		if drop_position != -1:
			moving['key'] = moving['key'].replace(original_data['orig_path'], destination_data['path'] + destination_data['name'] + "/")
			moving['value']['path'] = destination_data['path'] + destination_data['name'] + "/"
		else:
			moving['key'] = moving['key'].replace(original_data['orig_path'], destination_data['path'])
			moving['value']['path'] = destination_data['path']
		
	else:
		moving['key'] = moving['key'].replace(original_data['orig_path'], destination_data['path'])
		moving['value']['path'] = destination_data['path']
	
	flat_structure[tree +"_Array"].insert(insert_position, moving)
	
	
	flat_structure = editor_array_to_flat_structure(flat_structure,tree)
	DialogicResources.save_resource_folder_flat_structure(flat_structure)


static func add_file_to_folder(flat_structure:Dictionary, tree:String,  path:Dictionary, file_name:String, existing_data:Dictionary = {}):
	var insert_position_data = flat_structure[tree + "_Array"][path['step']]
	var insert_position = path['step']
	#advance the position to scroll past the subfolders if inserting from top of a folder
	
	var current_position = flat_structure[tree + "_Array"][insert_position]['key'].rstrip("/.")
	if insert_position == 0:
		current_position = "/"
	while insert_position + 1 < flat_structure[tree + "_Array"].size():
		
		var next_position = flat_structure[tree + "_Array"][insert_position + 1]['key']
		if  next_position.trim_prefix(current_position).count('/') == 0 or next_position.trim_prefix(current_position) == next_position:
			break
		insert_position = insert_position + 1
	
	if existing_data.empty():
		var new_data = {}
		
		if "/." in insert_position_data['key']:
			new_data['key'] = insert_position_data['key'].rstrip('.') + file_name
			new_data['value'] = {'category': tree, 'name': file_name, "color": Color.white, 'file': file_name, 'path': insert_position_data['key'].rstrip('.')}	
		else: 
			new_data['key'] = insert_position_data['value']['path'] + file_name
			new_data['value'] = {'category': tree, 'name': file_name, "color": Color.white, 'file': file_name, 'path': insert_position_data['value']['path']}	
		
		if tree == "Definitions":
			new_data['value']['type'] = path['type']
			new_data['value']['id'] = file_name
			if path['type'] == 0:
				new_data['value']['name'] = "New value"
				new_data['key'] = insert_position_data['key'].rstrip('.') + "New value"
			elif path['type'] == 1:
				new_data['value']['name'] = "New glossary entry"
				new_data['key'] = insert_position_data['key'].rstrip('.') + "New glossary entry"
				
		flat_structure[tree + "_Array"].insert(insert_position + 1, new_data)
	else:
		existing_data['key'] = path['path'] + "/" + existing_data['value']['name']
		existing_data['value']['path'] = path['path']
		flat_structure[tree + "_Array"].insert(insert_position + 1, existing_data)
	
	flat_structure = editor_array_to_flat_structure(flat_structure,tree)
	DialogicResources.save_resource_folder_flat_structure(flat_structure)

static func remove_file_from_folder(flat_structure:Dictionary, tree:String,  path:Dictionary):
	flat_structure[tree +"_Array"].remove(path['step'])
	
	flat_structure = editor_array_to_flat_structure(flat_structure, tree)
	DialogicResources.save_resource_folder_flat_structure(flat_structure)

static func rename_file(flat_structure:Dictionary, tree:String,  path:Dictionary, new_name:String):
	#forward slashes are disallowed in names, we will replace them with a hyphen
	new_name = new_name.replace("/", "-")
	
	var insert_position = path['step']

	flat_structure[tree + "_Array"][insert_position]['key'] = flat_structure[tree + "_Array"][insert_position]['value']['path'] + new_name
	flat_structure[tree + "_Array"][insert_position]['value']['name'] = new_name

	flat_structure = editor_array_to_flat_structure(flat_structure,tree)
	DialogicResources.save_resource_folder_flat_structure(flat_structure)

## STRUCTURE UPDATES
#should be called when files got deleted and on program start
static func update_resource_folder_structure():
	var character_files = DialogicResources.listdir(DialogicResources.get_path('CHAR_DIR'))
	var timeline_files = DialogicResources.listdir(DialogicResources.get_path('TIMELINE_DIR')) 
	var theme_files = DialogicResources.listdir(DialogicResources.get_path('THEME_DIR'))
	var definition_files = get_default_definitions_dict().keys()
	
	var folder_structure = DialogicResources.get_resource_folder_structure()
	
	folder_structure['folders']['Timelines'] = check_folders_section(folder_structure['folders']['Timelines'], timeline_files)
	folder_structure['folders']['Characters'] = check_folders_section(folder_structure['folders']['Characters'], character_files)
	folder_structure['folders']['Themes'] = check_folders_section(folder_structure['folders']['Themes'], theme_files)
	folder_structure['folders']['Definitions'] = check_folders_section(folder_structure['folders']['Definitions'], definition_files)
	
	DialogicResources.save_resource_folder_structure(folder_structure)

# calls the check_folders_recursive
static func check_folders_section(section_structure: Dictionary, section_files:Array):
	var result = check_folders_recursive(section_structure, section_files)
	section_structure = result[0]
	section_structure['files'] += result[1]
	return section_structure

static func check_folders_recursive(folder_data: Dictionary, file_names:Array):
	if not folder_data.has('metadata'):
		folder_data['metadata'] = {'color':null, 'folded':false}
	for folder in folder_data['folders'].keys():
		var result = check_folders_recursive(folder_data["folders"][folder], file_names)
		folder_data['folders'][folder] = result[0]
		file_names = result[1]
	for file in folder_data['files']:
		if not file in file_names:
			folder_data["files"].erase(file)
			#print("[D] The file ", file, " was deleted!")
		else:
			file_names.erase(file)
	return [folder_data, file_names]


static func beautify_filename(animation_name: String) -> String:
	if animation_name == '[Default]' or animation_name == '[No Animation]':
		return animation_name
	var a_string = animation_name.get_file().trim_suffix('.gd')
	if '-' in a_string:
		a_string = a_string.split('-')[1].capitalize()
	else:
		a_string = a_string.capitalize()
	return a_string
	
static func flat_structure_to_editor_array(flat_structure: Dictionary, tree:String="all") -> Dictionary:
	if tree != "all":
		flat_structure[tree + '_Array'] = []
		
		for key in flat_structure[tree].keys():
			flat_structure[tree+ '_Array'].push_back({'key': key, 'value': flat_structure[tree][key]})
	else:
		
		flat_structure['Timelines_Array'] = []
		flat_structure['Characters_Array'] = []
		flat_structure['Definitions_Array'] = []
		flat_structure['Themes_Array'] = []
		
		for key in flat_structure['Timelines'].keys():
			flat_structure['Timelines_Array'].push_back({'key': key, 'value': flat_structure['Timelines'][key]})

		for key in flat_structure['Characters'].keys():
			flat_structure['Characters_Array'].push_back({'key': key, 'value': flat_structure['Characters'][key]})
			
		for key in flat_structure['Definitions'].keys():
			flat_structure['Definitions_Array'].push_back({'key': key, 'value': flat_structure['Definitions'][key]})
			
		for key in flat_structure['Themes'].keys():
			flat_structure['Themes_Array'].push_back({'key': key, 'value': flat_structure['Themes'][key]})
			
	return flat_structure
	
static func editor_array_to_flat_structure(flat_structure: Dictionary, tree:String="all") -> Dictionary:
	if tree != "all":
		flat_structure[tree] = {}
		
		for idx in flat_structure[tree + '_Array'].size():
			flat_structure[tree][flat_structure[tree + '_Array'][idx]['key']] = flat_structure[tree + '_Array'][idx]['value']
		
	else:
		flat_structure['Timelines'] = {}
		flat_structure['Characters'] = {}
		flat_structure['Definitions'] = {}
		flat_structure['Themes'] = {}
		
		for idx in flat_structure['Timelines_Array'].size():
			flat_structure['Timelines'][flat_structure['Timelines_Array'][idx]['key']] = flat_structure['Timelines_Array'][idx]['value']
			
		for idx in flat_structure['Characters_Array'].size():
			flat_structure['Characters'][flat_structure['Characters_Array'][idx]['key']] = flat_structure['Characters_Array'][idx]['value']
			
		for idx in flat_structure['Definitions_Array'].size():
			flat_structure['Definitions'][flat_structure['Definitions_Array'][idx]['key']] = flat_structure['Definitions_Array'][idx]['value']
			
		for idx in flat_structure['Themes_Array'].size():
			flat_structure['Themes'][flat_structure['Themes_Array'][idx]['key']] = flat_structure['Themes_Array'][idx]['value']
			
		
	return flat_structure


## *****************************************************************************
##								USEFUL FUNCTIONS
## *****************************************************************************

static func generate_random_id() -> String:
	return str(OS.get_unix_time()) + '-' + str(100 + randi()%899+1)


static func compare_dicts(dict_1: Dictionary, dict_2: Dictionary) -> bool:
	# I tried using the .hash() function but it was returning different numbers
	# even when the dictionary was exactly the same.
	if str(dict_1) != "Null" and str(dict_2) != "Null":
		if str(dict_1) == str(dict_2):
			return true
	return false


static func path_fixer_load(path):
	# This function was added because some of the default assets shipped with
	# Dialogic 1.0 were moved for version 1.1. If by any chance they still
	# Use those resources, we redirect the paths from the old place to the new
	# ones. This can be safely removed and replace all instances of 
	# DialogicUtil.path_fixer_load(x) with just load(x) on version 2.0
	# since we will break compatibility.
	
	match path:
		'res://addons/dialogic/Fonts/DefaultFont.tres':
			return load("res://addons/dialogic/Example Assets/Fonts/DefaultFont.tres")
		'res://addons/dialogic/Fonts/GlossaryFont.tres':
			return load('res://addons/dialogic/Example Assets/Fonts/GlossaryFont.tres')
		'res://addons/dialogic/Images/background/background-1.png':
			return load('res://addons/dialogic/Example Assets/backgrounds/background-1.png')
		'res://addons/dialogic/Images/background/background-2.png':
			return load('res://addons/dialogic/Example Assets/backgrounds/background-2.png')
		'res://addons/dialogic/Images/next-indicator.png':
			return load('res://addons/dialogic/Example Assets/next-indicator/next-indicator.png')

	return load(path)

# This function contains necessary updates.
# This should be deleted in 2.0
static func resource_fixer():
	var update_index = DialogicResources.get_settings_config().get_value("updates", "updatenumber", 0)
	
	if update_index < 1:
		print("[D] Update NR. "+str(update_index)+" | Adds event ids. Don't worry about this.")
		for timeline_info in get_timeline_list():
			var timeline = DialogicResources.get_timeline_json(timeline_info['file'])
			
			var events = timeline["events"]
			for i in events:
				if not i.has("event_id"):
					match i:
						# MAIN EVENTS
						# Text event
						{'text', 'character', 'portrait'}:
							i['event_id'] = 'dialogic_001'
						# Join event
						{'character', 'action', 'position', 'portrait',..}:
							i['event_id'] = 'dialogic_002'
						# Character Leave event 
						{'character', 'action'}:
							i['event_id'] = 'dialogic_003'
						
						# LOGIC EVENTS
						# Question event
						{'question', 'options', ..}:
							i['event_id'] = 'dialogic_010'
						# Choice event
						{'choice', ..}:
							i['event_id'] = 'dialogic_011'
						# Condition event
						{'condition', 'definition', 'value'}:
							i['event_id'] = 'dialogic_012'
						# End Branch event
						{'endbranch'}:
							i['event_id'] = 'dialogic_013'
						# Set Value event
						{'set_value', 'definition', ..}:
							i['event_id'] = 'dialogic_014'
						
						# TIMELINE EVENTS
						# Change Timeline event
						{'change_timeline'}:
							i['event_id'] = 'dialogic_020'
						# Change Backround event
						{'background'}:
							i['event_id'] = 'dialogic_021'
						# Close Dialog event
						{'close_dialog', ..}:
							i['event_id'] = 'dialogic_022'
						# Wait seconds event
						{'wait_seconds'}:
							i['event_id'] = 'dialogic_023'
						# Set Theme event
						{'set_theme'}:
							i['event_id'] = 'dialogic_024'
						
						# AUDIO EVENTS
						# Audio event
						{'audio', 'file', ..}:
							i['event_id'] = 'dialogic_030'
						# Background Music event
						{'background-music', 'file', ..}:
							i['event_id'] = 'dialogic_031'
						
						# GODOT EVENTS
						# Emit signal event
						{'emit_signal'}:
							i['event_id'] = 'dialogic_040'
						# Change Scene event
						{'change_scene'}:
							i['event_id'] = 'dialogic_041'
						# Call Node event
						{'call_node'}:
							i['event_id'] = 'dialogic_042'
						# No Skip event
						{'block_input'}:
							i['event_id'] = 'dialogic_050'
			timeline['events'] = events
			DialogicResources.set_timeline(timeline)
	if update_index < 2:
		# Updates the text alignment to be saved as int like all anchors
		print("[D] Update NR. "+str(update_index)+" | Changes how some theme values are saved. No need to worry about this.")
		for theme_info in get_theme_list():
			var theme = DialogicResources.get_theme_config(theme_info['file'])

			match theme.get_value('text', 'alignment', 'Left'):
				'Left':
					DialogicResources.set_theme_value(theme_info['file'], 'text', 'alignment', 0)
				'Center':
					DialogicResources.set_theme_value(theme_info['file'], 'text', 'alignment', 1)
				'Right':
					DialogicResources.set_theme_value(theme_info['file'], 'text', 'alignment', 2)
	
	if update_index < 3:
		# Character Join and Character Leave have been unified to a new Character event
		print("[D] Update NR. "+str(update_index)+" | Removes Character Join and Character Leave events in favor of the new 'Character' event. No need to worry about this.")
		for timeline_info in get_timeline_list():
			var timeline = DialogicResources.get_timeline_json(timeline_info['file'])
			var events = timeline["events"]
			for i in range(len(events)):
				if events[i]['event_id'] == 'dialogic_002':
					var new_event = {
						'event_id':'dialogic_002',
						'type':0,
						'character':events[i].get('character', ''),
						'portrait':events[i].get('portrait','Default'),
						'position':events[i].get('position'),
						'animation':'[Default]',
						'animation_length':0.5,
						'mirror_portrait':events[i].get('mirror', false),
						'z_index': events[i].get('z_index', 0),
						}
					if new_event['portrait'].empty(): new_event['portrait'] = 'Default'
					events[i] = new_event
				elif events[i]['event_id'] == 'dialogic_003':
					var new_event = {
						'event_id':'dialogic_002',
						'type':1,
						'character':events[i].get('character', ''),
						'animation':'[Default]',
						'animation_length':0.5,
						'mirror_portrait':events[i].get('mirror', false),
						'z_index':events[i].get('z_index', 0),
						}
					events[i] = new_event
			timeline['events'] = events
			DialogicResources.set_timeline(timeline)
	
	DialogicResources.set_settings_value("updates", "updatenumber", 3)
	
	if !ProjectSettings.has_setting('input/dialogic_default_action'):
		print("[D] Added the 'dialogic_default_action' to the InputMap. This is the default if you didn't select a different one in the dialogic settings. You will have to force the InputMap editor to update before you can see the action (reload project or add a new input action).")
		var input_enter = InputEventKey.new()
		input_enter.scancode = KEY_ENTER
		var input_left_click = InputEventMouseButton.new()
		input_left_click.button_index = BUTTON_LEFT
		input_left_click.pressed = true
		var input_space = InputEventKey.new()
		input_space.scancode = KEY_SPACE
		var input_x = InputEventKey.new()
		input_x.scancode = KEY_X
		var input_controller = InputEventJoypadButton.new()
		input_controller.button_index = JOY_BUTTON_0
	
		ProjectSettings.set_setting('input/dialogic_default_action', {'deadzone':0.5, 'events':[input_enter, input_left_click, input_space, input_x, input_controller]})
		ProjectSettings.save()
		if DialogicResources.get_settings_value('input', 'default_action_key', '[Default]') == '[Default]':
			DialogicResources.set_settings_value('input', 'default_action_key', 'dialogic_default_action')

static func get_editor_scale(ref) -> float:
	# There hasn't been a proper way of reliably getting the editor scale
	# so this function aims at fixing that by identifying what the scale is and
	# returning a value to use as a multiplier for manual UI tweaks
	
	# The way of getting the scale could change, but this is the most reliable
	# solution I could find that works in many different computer/monitors.
	var _scale = ref.get_constant("inspector_margin", "Editor")
	_scale = _scale * 0.125
	
	return _scale


static func list_dir(path: String) -> Array:
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true)

	var file = dir.get_next()
	while file != '':
		files += [file]
		file = dir.get_next()
	return files
	
## *****************************************************************************
##							DIALOGIC FLAT LOADER
## *****************************************************************************

static func get_flat_folders_list(include_folders: bool = true) -> Dictionary:
	
	var timeline_folder_breakdown = {}
	var character_folder_breakdown = {}
	var definition_folder_breakdown = {}
	var theme_folder_breakdown = {}
	
	# load the main folder strucutre, and then use the DialogicUtils to match their names
	var structure = DialogicResources.get_resource_folder_flat_structure()
	var timeline_list = get_timeline_list()
	var character_list = get_character_list()
	var definition_list = get_default_definitions_list()
	var theme_list = get_theme_list()
	
	
	# populate the data from the resources
	for timeline in timeline_list:
		if timeline['file'] in structure['Timelines']:
			if "/" in timeline['name']:
				print("[D] Warning: Dialogic 1.5 makes internal changes that disallow forward slashes in file and folder names")
				print("    The following timeline needs to be renamed, please update references in your code:   " + timeline['name'])
				print("    This warning will continue until you change the name of this timeline")		
			timeline['path'] = structure['Timelines'][timeline['file']] + timeline['name'].replace("/","-")
			structure['Timelines'][timeline['file']]= timeline
	
	for character in character_list:
		if character['file'] in structure['Characters']:
			if "/" in character['name']:
				print("[D] Warning: Dialogic 1.5 makes internal changes that disallow forward slashes in file and folder names")
				print("    The following character needs to be renamed, please update references in your code:   " + character['name'])
				print("    This warning will continue until you change the name of this character")
			character['path'] = structure['Characters'][character['file']] + character['name'].replace("/","-")
			structure['Characters'][character['file']]= character
		
	for definition in definition_list:
		if definition['id'] in structure['Definitions']:
			if "/" in definition['name']:
				print("[D] Warning: Dialogic 1.5 makes internal changes that disallow forward slashes in file and folder names")
				print("    The following definition needs to be renamed, please update references in your code:   " + definition['name'])
				print("    This warning will continue until you change the name of this definition")
			definition['path'] = structure['Definitions'][definition['id']] + definition['name'].replace("/","-")
			definition['file'] = definition['id']
			structure['Definitions'][definition['id']]= definition
		
	for theme in theme_list:
		if theme['file'] in structure['Themes']:
			if "/" in theme['name']:
				print("[D] Warning: Dialogic 1.5 makes internal changes that disallow forward slashes in file and folder names")
				print("    The following theme needs to be renamed, please update references in your code:   " + theme['name'])
				print("    This warning will continue until you change the name of this theme")
			theme['path'] = structure['Themes'][theme['file']] + theme['name'].replace("/","-")
			structure['Themes'][theme['file']]= theme
		
	# After that we put them in the order we need to make the folder paths easiest to use
	for timeline in structure['Timelines'].keys():
		if ".json" in timeline:
			timeline_folder_breakdown[structure['Timelines'][timeline]['path']] = structure['Timelines'][timeline]
		elif include_folders:
			timeline_folder_breakdown[timeline] = structure['Timelines'][timeline]

	for character in structure['Characters'].keys():
		if ".json" in character:
			character_folder_breakdown[structure['Characters'][character]['path']] = structure['Characters'][character]
		elif include_folders:
			character_folder_breakdown[character] = structure['Characters'][character]


	for definition in structure['Definitions'].keys():
		
		if !"/." in definition:
			definition_folder_breakdown[structure['Definitions'][definition]['path']] = structure['Definitions'][definition]
		elif include_folders:
			definition_folder_breakdown[definition] = structure['Definitions'][definition]


	for theme in structure['Themes'].keys():
		if ".json" in theme:
			theme_folder_breakdown[structure['Themes'][theme]['path']] = structure['Themes'][theme]		
		elif include_folders:
			theme_folder_breakdown[theme] = structure['Themes'][theme]
			
	var flatten = {}
	flatten['Timelines'] = timeline_folder_breakdown
	flatten['Characters'] = character_folder_breakdown
	flatten['Definitions'] = definition_folder_breakdown
	flatten['Themes'] = theme_folder_breakdown
	
	return flatten


## *****************************************************************************
##							DIALOGIC_SORTER CLASS
## *****************************************************************************

# This class is only used by this script to sort the resource lists
class DialgicSorter:

	static func key_available(key, a: Dictionary) -> bool:
		return key in a.keys() and not a[key].empty()

	static func get_compare_value(a: Dictionary) -> String:
		if key_available('display_name', a):
			return a['display_name']
		
		if key_available('name', a):
			return a['name']
		
		if key_available('id', a):
			return a['id']
		
		if 'metadata' in a.keys():
			var a_metadata = a['metadata']
			if key_available('name', a_metadata):
				return a_metadata['name']
			if key_available('file', a_metadata):
				return a_metadata['file']
		return ''

	static func sort_resources(a: Dictionary, b: Dictionary):
		return get_compare_value(a).to_lower() < get_compare_value(b).to_lower()


