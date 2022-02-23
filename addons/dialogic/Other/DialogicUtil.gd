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


## SETTERS
static func set_folder_content_recursive(path_array: Array, orig_data: Dictionary, new_data: Dictionary) -> Dictionary:
	if len(path_array) == 1:
		if path_array[0] in orig_data['folders'].keys():
			if new_data.empty():
				orig_data['folders'].erase(path_array[0])
			else:
				orig_data["folders"][path_array[0]] = new_data
	else:
		var current_folder = path_array.pop_front()
		orig_data["folders"][current_folder] = set_folder_content_recursive(path_array, orig_data["folders"][current_folder], new_data)
	return orig_data

static func set_folder_at_path(path: String, data:Dictionary):
	var orig_structure = get_full_resource_folder_structure()
	var new_data = set_folder_content_recursive(path.split("/"), orig_structure, data)
	DialogicResources.save_resource_folder_structure(new_data)
	return OK

## FOLDER METADATA
static func set_folder_meta(folder_path: String, key:String, value):
	var data = get_folder_at_path(folder_path)
	data['metadata'][key] = value
	set_folder_at_path(folder_path, data)

static func get_folder_meta(folder_path: String, key:String):
	return get_folder_at_path(folder_path)['metadata'][key]


## FOLDER FUNCTIONS
static func add_folder(path:String, folder_name:String):
	# check if the name is allowed
	if folder_name in get_folder_at_path(path)['folders'].keys():
		print("[D] A folder with the name '"+folder_name+"' already exists in the target folder '"+path+"'.")
		return ERR_ALREADY_EXISTS
	
	var folder_data = get_folder_at_path(path)
	folder_data['folders'][folder_name] = {"folders":{}, "files":[], 'metadata':{'color':null, 'folded':false}}
	set_folder_at_path(path, folder_data)
	
	return OK

static func remove_folder(folder_path:String, delete_files:bool = true):
	#print("[D] Removing 'Folder' "+folder_path)
	for folder in get_folder_at_path(folder_path)['folders']:
		remove_folder(folder_path+"/"+folder, delete_files)
	
	if delete_files:
		for file in get_folder_at_path(folder_path)['files']:
			#print("[D] Removing file ", file)
			match folder_path.split("/")[0]:
				'Timelines':
					DialogicResources.delete_timeline(file)
				'Characters':
					DialogicResources.delete_character(file)
				'Definitions':
					DialogicResources.delete_default_definition(file)
				'Themes':
					DialogicResources.delete_theme(file)
	set_folder_at_path(folder_path, {})

static func rename_folder(path:String, new_folder_name:String):
	# check if the name is allowed
	if new_folder_name in get_folder_at_path(get_parent_path(path))['folders'].keys():
		print("[D] A folder with the name '"+new_folder_name+"' already exists in the target folder '"+get_parent_path(path)+"'.")
		return ERR_ALREADY_EXISTS
	elif new_folder_name.empty():
		return ERR_PRINTER_ON_FIRE
		
	
	# save the content
	var folder_content = get_folder_at_path(path)
	
	# remove the old folder BUT NOT THE FILES !!!!!
	remove_folder(path, false)
	
	# add the new folder
	add_folder(get_parent_path(path), new_folder_name)
	var new_path = get_parent_path(path)+ "/"+new_folder_name
	set_folder_at_path(new_path, folder_content)

	return OK

static func move_folder_to_folder(orig_path, target_folder):
	# check if the name is allowed
	if orig_path.split("/")[-1] in get_folder_at_path(target_folder)['folders'].keys():
		print("[D] A folder with the name '"+orig_path.split("/")[-1]+"' already exists in the target folder '"+target_folder+"'.")
		return ERR_ALREADY_EXISTS
	
	# save the content
	var folder_content = get_folder_at_path(orig_path)
	
	# remove the old folder BUT DON'T DELETE THE FILES!!!!!!!!!!!
	# took me ages to find this when I forgot it..
	remove_folder(orig_path, false)
	
	# add the new folder
	var folder_name = orig_path.split("/")[-1]
	add_folder(target_folder, folder_name)
	var new_path = target_folder+ "/"+folder_name
	set_folder_at_path(new_path, folder_content)
	
	return OK

## FILE FUNCTIONS
static func move_file_to_folder(file_name, orig_folder, target_folder):
	remove_file_from_folder(orig_folder, file_name)
	add_file_to_folder(target_folder, file_name)

static func add_file_to_folder(folder_path, file_name):
	var folder_data = get_folder_at_path(folder_path)
	folder_data["files"].append(file_name)
	set_folder_at_path(folder_path, folder_data)

static func remove_file_from_folder(folder_path, file_name):
	var folder_data = get_folder_at_path(folder_path)
	folder_data["files"].erase(file_name)
	set_folder_at_path(folder_path, folder_data)


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
