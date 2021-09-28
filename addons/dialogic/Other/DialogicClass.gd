extends Node

## Exposed and safe to use methods for Dialogic
## See documentation under 'https://github.com/coppolaemilio/dialogic' or in the editor:

## ### /!\ ###
## Do not use methods from other classes as it could break the plugin's integrity
## ### /!\ ###

## Trying to follow this documentation convention: https://github.com/godotengine/godot/pull/41095
class_name Dialogic


## Refactor the start function for 2.0 there should be a cleaner way to do it :)

## Starts the dialog for the given timeline and returns a Dialog node.
## You must then add it manually to the scene to display the dialog.
##
## Example:
## var new_dialog = Dialogic.start('Your Timeline Name Here')
## add_child(new_dialog)
##
## This is similar to using the editor:
## you can drag and drop the scene located at /addons/dialogic/Dialog.tscn 
## and set the current timeline via the inspector.
##
## @param timeline				The timeline to load. You can provide the timeline name or the filename.
## @param reset_saves			True to reset dialogic saved data such as definitions.
## @param dialog_scene_path		If you made a custom Dialog scene or moved it from its default path, you can specify its new path here.
## @param debug_mode			Debug is disabled by default but can be enabled if needed.
## @param use_canvas_instead	Create the Dialog inside a canvas layer to make it show up regardless of the camera 2D/3D situation.
## @returns						A Dialog node to be added into the scene tree.
static func start(timeline: String, reset_saves: bool=false, dialog_scene_path: String="res://addons/dialogic/Nodes/DialogNode.tscn", debug_mode: bool=false, use_canvas_instead=true):
	var dialog_scene = load(dialog_scene_path)
	var dialog_node = null
	var canvas_dialog_node = null
	var returned_dialog_node = null
	
	if use_canvas_instead:
		var canvas_dialog_script = load("res://addons/dialogic/Nodes/canvas_dialog_node.gd")
		canvas_dialog_node = canvas_dialog_script.new()
		canvas_dialog_node.set_dialog_node_scene(dialog_scene)
		dialog_node = canvas_dialog_node.dialog_node
	else:
		dialog_node = dialog_scene.instance()
	
	dialog_node.reset_saves = reset_saves
	dialog_node.debug_mode = debug_mode
	
	returned_dialog_node = dialog_node if not canvas_dialog_node else canvas_dialog_node
	
	if timeline.ends_with('.json'):
		for t in DialogicUtil.get_timeline_list():
			if t['file'] == timeline:
				dialog_node.timeline = t['file']
				return returned_dialog_node
		# No file found. Show error
		dialog_node.dialog_script = {
			"events":[
				{"event_id":'dialogic_001',
				"character":"",
				"portrait":"",
				"text":"[Dialogic Error] Loading dialog [color=red]" + timeline + "[/color]. It seems like the timeline doesn't exists. Maybe the name is wrong?"
			}]
		}
		return returned_dialog_node
	else:
		var timeline_file = get_timeline_file_from_name(timeline)
		if timeline_file:
			dialog_node.timeline = timeline_file
			return returned_dialog_node
	# Just in case everything else fails.
	return returned_dialog_node



################################################################################
## 						BUILT-IN SAVING/LOADING
################################################################################


## Similar to the start function, but loads state info and definitions
## If you leave save_name empty it will try to load from the current state
## 
## @param save_name			The name of the save folder.
##							Leaving this empty load from the default files.
## @param default_timeline	Will load if no save name is given AND nothing was imported
##
## The other @params work like the ones in start()
## @returns 				A Dialog node to be added into the scene tree.
static func start_from_save(save_name: String = '', default_timeline : String = '', dialog_scene_path: String="res://addons/dialogic/Nodes/DialogNode.tscn", debug_mode: bool=false, use_canvas_instead=true) -> Node:
	var dialog_scene = load(dialog_scene_path)
	var dialog_node = null
	var canvas_dialog_node = null
	var returned_dialog_node = null

	if use_canvas_instead:
		var canvas_dialog_script = load("res://addons/dialogic/Nodes/canvas_dialog_node.gd")
		canvas_dialog_node = canvas_dialog_script.new()
		canvas_dialog_node.set_dialog_node_scene(dialog_scene)
		dialog_node = canvas_dialog_node.dialog_node
	else:
		dialog_node = dialog_scene.instance()

	dialog_node.reset_saves = false
	dialog_node.debug_mode = debug_mode

	returned_dialog_node = dialog_node if not canvas_dialog_node else canvas_dialog_node
	
	if save_name == '/':
		# this will load from current state (default save or imported data)
		if (Engine.get_main_loop().has_meta('last_dialog_state') 
		  and not Engine.get_main_loop().get_meta('last_dialog_state').empty()
		  and not Engine.get_main_loop().get_meta('last_dialog_state').get('timeline', '').empty()):
			dialog_node.resume_state_from_info(Engine.get_main_loop().get_meta('last_dialog_state'))
			return returned_dialog_node
	else:
		# this if a save_name was specified or it will load the default save
		load_from_save(save_name)
	
	## now check if the loaded data is usable
	if (Engine.get_main_loop().has_meta('last_dialog_state') 
	  and not Engine.get_main_loop().get_meta('last_dialog_state').empty()
	  and not Engine.get_main_loop().get_meta('last_dialog_state').get('timeline', '').empty()):
		dialog_node.resume_state_from_info(Engine.get_main_loop().get_meta('last_dialog_state'))
	# otherwise load the default_timeline
	else:
		if default_timeline == '':
			print('[D] Saved/imported data not found. You should provide a default timeline for these cases!')
			return Node.new()
		var timeline_file = get_timeline_file_from_name(default_timeline)
		if timeline_file:
			dialog_node.timeline = timeline_file
		else:
			print("[D] Unable to find timeline '"+default_timeline+"'.")
	return returned_dialog_node


## Saves the current definitions and the latest added dialog nodes state info.
## 
## @param save_name		The name of the save folder. To load this save you have to specify the same
##						If the save folder doesn't exist it will be created. 
##						Leaving this empty will overwrite the default files.
static func save_current_info(save_name: String = '', check_autosave = false) -> void:
	if check_autosave and not get_autosave():
		return
	var current_dialog_info = {}
	if has_current_dialog_node():
		current_dialog_info = Engine.get_main_loop().get_meta('latest_dialogic_node').get_current_state_info()
	var game_state = {}
	if Engine.get_main_loop().has_meta('game_state'):
		game_state = Engine.get_main_loop().get_meta('game_state')
	var save_data = {
		'game_state': game_state,
		'dialog_state': current_dialog_info
		}
	save_state_and_definitions(save_name, save_data)


## Returns an array with the names of all available saves.
## 
## @param save_name		The name of the save folder.
static func get_save_names_array() -> Array:
	return DialogicResources.get_saves_folders()


## Will permanently erase the save data with the given name.
## 
## @param save_name		The name of the save folder.
static func erase_save(save_name: String) -> void:
	DialogicResources.remove_save_folder(save_name)


## Whether a save can be performed
##
## @returns				True if a save can be performed; otherwise False
static func has_current_dialog_node() -> bool:
	return Engine.get_main_loop().has_meta('latest_dialogic_node') and is_instance_valid(Engine.get_main_loop().get_meta('latest_dialogic_node'))


## Resets the state and definitions of the given save slot
##
## By default this will also LOAD that reseted save
static func reset_saves(save_name: String = '', reload:= true) -> void:
	DialogicResources.reset_save(save_name)
	if reload: load_from_save(save_name)

## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## 						GAME STATE
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# the game state is a global dictionary that can be used to store custom data
# these functions should be renamed in 2.0! These names are outdated.

# this sets a value in the GAME STATE dictionary
static func get_saved_state_general_key(key: String, default = '') -> String:
	if not Engine.get_main_loop().has_meta('game_state'):
		return default
	if key in Engine.get_main_loop().get_meta('game_state').keys():
		return Engine.get_main_loop().get_meta('game_state')[key]
	else:
		return default


# this gets a value from the GAME STATE dictionary
static func set_saved_state_general_key(key: String, value) -> void:
	if not Engine.get_main_loop().has_meta('game_state'):
		Engine.get_main_loop().set_meta('game_state', {})
	Engine.get_main_loop().get_meta('game_state')[key] = str(value)
	save_current_info('', true)


## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## 						EXPORT / IMPORT
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# this returns a dictionary with the DEFINITIONS, the GAME STATE and the DIALOG STATE
static func export(dialog_node = null) -> Dictionary:
	var current_dialog_info = {}
	if dialog_node == null and has_current_dialog_node():
		dialog_node = Engine.get_main_loop().get_meta('latest_dialogic_node')
	if dialog_node:
		current_dialog_info = dialog_node.get_current_state_info()
	return {
		'definitions': get_definitions(),
		'state': Engine.get_main_loop().get_meta('game_state'),
		'dialog_state': current_dialog_info
	}


# this loads a dictionary with GAME STATE, DEFINITIONS and DIALOG_STATE 
static func import(data: Dictionary) -> void:
	Engine.get_main_loop().set_meta('definitions', data['definitions'])
	Engine.get_main_loop().set_meta('game_state', data['state'])
	Engine.get_main_loop().set_meta('last_dialog_state', data.get('dialog_state', null))
	set_current_timeline(get_saved_state_general_key('timeline'))

################################################################################
## 					NOT TO BE USED FROM OUTSIDE
################################################################################

#
## this loads the saves definitions and returns the saves state_info ditionary
static func load_from_save(save_name: String = '') -> Dictionary:
	Engine.get_main_loop().set_meta('definitions', DialogicResources.get_saved_definitions(save_name))
	var state_info = DialogicResources.get_saved_state_info(save_name)
	Engine.get_main_loop().set_meta('last_dialog_state', state_info.get('dialog_state', null))
	Engine.get_main_loop().set_meta('game_state', state_info.get('game_state', null))
	
	return state_info.get('dialog_state', {})


# --------------------------------------------------------------------------------------------------
# The following functions existed previously on the DialogicSingleton.gd singleton.
# I removed that one and moved the functions here.


## this saves the current definitions and the given state info into the save folder @save_name
static func save_state_and_definitions(save_name: String, state_info: Dictionary) -> void:
	DialogicResources.save_definitions(save_name, get_definitions())
	DialogicResources.save_state_info(save_name, state_info)


static func get_autosave() -> bool:
	if Engine.get_main_loop().has_meta('autoload'):
		return Engine.get_main_loop().get_meta('autoload')
	return true


static func set_autosave(autoload):
	Engine.get_main_loop().set_meta('autoload', autoload)


static func set_current_timeline(timeline):
	Engine.get_main_loop().set_meta('current_timeline', timeline)
	return timeline


static func get_current_timeline():
	var timeline
	timeline = Engine.get_main_loop().get_meta('current_timeline')
	if timeline == null:
		timeline = ''
	return timeline


static func get_definitions() -> Dictionary:
	var definitions
	if Engine.get_main_loop().has_meta('definitions'):
		definitions = Engine.get_main_loop().get_meta('definitions')
	else:
		definitions = DialogicResources.get_default_definitions()
		Engine.get_main_loop().set_meta('definitions', definitions)
	return definitions


static func set_variable(name: String, value):
	var exists = false
	for d in get_definitions()['variables']:
		if d['name'] == name:
			d['value'] = str(value)
			exists = true
	if exists == false:
		# TODO it would be great to automatically generate that missing variable here so they don't
		# have to create it from the editor. 
		print('[Dialogic] Warning! the variable [' + name + '] doesn\'t exists. Create it from the Dialogic editor.')
	return value


static func get_variable(name: String, default = null):
	for d in get_definitions()['variables']:
		if d['name'] == name:
			return d['value']
	print('[Dialogic] Warning! the variable [' + name + '] doesn\'t exists.')
	return default


static func set_glossary_from_id(id: String, title: String, text: String, extra:String) -> void:
	var target_def: Dictionary;
	for d in get_definitions()['glossary']:
		if d['id'] == id:
			target_def = d;
	if target_def != null:
		if title and title != "[No Change]":
			target_def['title'] = title
		if text and text != "[No Change]":
			target_def['text'] = text
		if extra and extra != "[No Change]":
			target_def['extra'] = extra


static func set_variable_from_id(id: String, value: String, operation: String) -> void:
	var target_def: Dictionary;
	for d in get_definitions()['variables']:
		if d['id'] == id:
			target_def = d;
	if target_def != null:
		var converted_set_value = value
		var converted_target_value = target_def['value']
		var is_number = converted_set_value.is_valid_float() and converted_target_value.is_valid_float()
		if is_number:
			converted_set_value = float(value)
			converted_target_value = float(target_def['value'])
		var result = target_def['value']
		# Do nothing for -, * and / operations on string
		match operation:
			'=':
				result = converted_set_value
			'+':
				result = converted_target_value + converted_set_value
			'-':
				if is_number:
					result = converted_target_value - converted_set_value
			'*':
				if is_number:
					result = converted_target_value * converted_set_value
			'/':
				if is_number:
					result = converted_target_value / converted_set_value
		target_def['value'] = str(result)


static func get_timeline_file_from_name(timeline_name_path: String) -> String:
	var timelines = DialogicUtil.get_full_resource_folder_structure()['folders']['Timelines']
	var parts = timeline_name_path.split('/', false)
	if parts.size() > 1:
		var current_data
		var current_depth = 0
		for p in parts:
			if current_depth == 0:
				# Starting the crawl
				current_data = timelines['folders'][p]
			elif current_depth == parts.size() - 1:
				# The final destination
				for t in DialogicUtil.get_timeline_list():
					for f in current_data['files']:
						if t['file'] == f && t['name'] == p:
							return t['file']
							
			else:
				# Still going deeper
				current_data = current_data['folders'][p]
			current_depth += 1
	else:
		# Searching for any timeline that could match that name
		for t in DialogicUtil.get_timeline_list():
			if parts.size():
				if t['name'] == parts[0]:
					return t['file']
	return ''
