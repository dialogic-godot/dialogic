tool
class_name DialogicUtil


static func get_character_list() -> Array:
	var characters: Array = []
	for file in DialogicResources.listdir(DialogicResources.get_path('CHAR_DIR')):
		if '.json' in file:
			var data: Dictionary     = DialogicResources.get_character_json(file)
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


static func get_sorted_character_list():
	var array = get_character_list()
	array.sort_custom(DialgicSorter, 'sort_resources')
	return array


static func get_timeline_list() -> Array:
	var timelines: Array = []
	for file in DialogicResources.listdir(DialogicResources.get_path('TIMELINE_DIR')):
		if '.json' in file:
			var data = DialogicResources.get_timeline_json(file)
			if data.has('error') == false:
				var metadata = data['metadata']
				var color = Color("#ffffff")
				if metadata.has('name'):
					timelines.append({'name':metadata['name'], 'color': color, 'file': file })
				else:
					timelines.append({'name':file.split('.')[0], 'color': color, 'file': file })
	return timelines


static func get_sorted_timeline_list():
	var array = get_timeline_list()
	array.sort_custom(DialgicSorter, 'sort_resources')
	return array


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


static func get_sorted_theme_list():
	var array = get_theme_list()
	array.sort_custom(DialgicSorter, 'sort_resources')
	return array


static func get_default_definitions_list() -> Array:
	return DialogicDefinitionsUtil.definitions_json_to_array(DialogicResources.get_default_definitions())


static func get_sorted_default_definitions_list():
	var array = get_default_definitions_list()
	array.sort_custom(DialgicSorter, 'sort_resources')
	return array


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
	
	DialogicResources.set_settings_value("updates", "updatenumber", 1)
	

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
