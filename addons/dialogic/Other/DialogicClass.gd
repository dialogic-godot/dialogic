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
##								If you leave it empty, it will try to load from current data
##								In that case, you should do  Dialogic.load() or Dialogic.import() before.
## @param default_timeline		If timeline == '' and no valid data was found, this will be loaded.
## @param dialog_scene_path		If you made a custom Dialog scene or moved it from its default path, you can specify its new path here.
## @param use_canvas_instead	Create the Dialog inside a canvas layer to make it show up regardless of the camera 2D/3D situation.
## @returns						A Dialog node to be added into the scene tree.
static func start(timeline: String = '', default_timeline: String ='', dialog_scene_path: String="res://addons/dialogic/Nodes/DialogNode.tscn", use_canvas_instead=true):
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
	
	returned_dialog_node = dialog_node if not canvas_dialog_node else canvas_dialog_node
	
	## 1. Case: A slot has been loaded OR data has been imported
	if timeline == '':
		if (Engine.get_main_loop().has_meta('last_dialog_state') 
			and not Engine.get_main_loop().get_meta('last_dialog_state').empty()
			and not Engine.get_main_loop().get_meta('last_dialog_state').get('timeline', '').empty()):
		
			dialog_node.resume_state_from_info(Engine.get_main_loop().get_meta('last_dialog_state'))
			return returned_dialog_node
		
		## The loaded data isn't complete
		elif (Engine.get_main_loop().has_meta('current_timeline')
			and not Engine.get_main_loop().get_meta('current_timeline').empty()):
				timeline = Engine.get_main_loop().get_meta('current_timeline')
		
		## Else load the default timeline
		else:
			timeline = default_timeline
	
	## 2. Case: A specific timeline should be started
	
	# check if it's a file name
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
	
	# else get the file from the name
	var timeline_file = _get_timeline_file_from_name(timeline)
	if timeline_file:
		dialog_node.timeline = timeline_file
		return returned_dialog_node
	
	# Just in case everything else fails.
	return returned_dialog_node

# Loads the given timeline into the active DialogNode
# This means it's state (theme, characters, background, music) is preserved.
#
# @param timeline				the name of the timeline to load
static func change_timeline(timeline: String) -> void:
	# Set Timeline
	set_current_timeline(timeline)
	
	# If there is a dialog node
	if has_current_dialog_node():
		var dialog_node = Engine.get_main_loop().get_meta('latest_dialogic_node')
		
		# Get file name
		var timeline_file = _get_timeline_file_from_name(timeline)
		
		dialog_node.change_timeline(timeline_file)
	else:
		print("[D] Tried to change timeline, but no DialogNode exists!")

# Immediately plays the next event.
#
# @param discreetly				determines whether the Passing Audio will be played in the process
static func next_event(discreetly: bool = false):
	
	# If there is a dialog node
	if has_current_dialog_node():
		var dialog_node = Engine.get_main_loop().get_meta('latest_dialogic_node')
		
		dialog_node.next_event(discreetly)


################################################################################
## 						Test to see if a timeline exists
################################################################################

## Check to see if a timeline with a given name/path exists. Useful for verifying
## before calling a timeline, or for automated tests to make sure timeline calls 
## are valid. Returns a boolean of true if the timeline exists, and false if it 
## does not. 
static func timeline_exists(timeline: String):
	var timeline_file = _get_timeline_file_from_name(timeline)
	if timeline_file:
		return true
	else:
		return false


################################################################################
## 						BUILT-IN SAVING/LOADING
################################################################################

## Loads the given slot
static func load(slot_name: String = ''):
	_load_from_slot(slot_name)
	Engine.get_main_loop().set_meta('current_save_slot', slot_name)


## Saves the current definitions and the latest added dialog nodes state info.
## 
## @param slot_name		The name of the save slot. To load this save you have to specify the same
##						If the slot folder doesn't exist it will be created. 
static func save(slot_name: String = '', is_autosave = false) -> void:
	# check if to save (if this is a autosave)
	if is_autosave and not get_autosave():
		return
	
	# gather the info
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
	
	# save the information
	_save_state_and_definitions(slot_name, save_data)


## Returns an array with the names of all available slots.
static func get_slot_names() -> Array:
	return DialogicResources.get_saves_folders()


## Will permanently erase the data in the given save_slot.
## 
## @param slot_name		The name of the slot folder.
static func erase_slot(slot_name: String) -> void:
	DialogicResources.remove_save_folder(slot_name)


## Whether a save can be performed
##
## @returns				True if a save can be performed; otherwise False
static func has_current_dialog_node() -> bool:
	return Engine.get_main_loop().has_meta('latest_dialogic_node') and is_instance_valid(Engine.get_main_loop().get_meta('latest_dialogic_node'))


## Resets the state and definitions of the given save slot
##
## By default this will also LOAD that reseted save
static func reset_saves(slot_name: String = '', reload:= true) -> void:
	DialogicResources.reset_save(slot_name)
	if reload: _load_from_slot(slot_name)


## Returns the currently loaded save slot
static func get_current_slot():
	if Engine.get_main_loop().has_meta('current_save_slot'):
		return Engine.get_main_loop().get_meta('current_save_slot')
	else:
		return ''

## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## 						EXPORT / IMPORT
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# this returns a dictionary with the DEFINITIONS, the GAME STATE and the DIALOG STATE
static func export(dialog_node = null) -> Dictionary:
	# gather the data
	var current_dialog_info = {}
	if dialog_node == null and has_current_dialog_node():
		dialog_node = Engine.get_main_loop().get_meta('latest_dialogic_node')
	if dialog_node:
		current_dialog_info = dialog_node.get_current_state_info()
	
	# return it
	return {
		'definitions': _get_definitions(),
		'state': Engine.get_main_loop().get_meta('game_state'),
		'dialog_state': current_dialog_info
	}


# this loads a dictionary with GAME STATE, DEFINITIONS and DIALOG_STATE 
static func import(data: Dictionary) -> void:
	## Tell the future we want to use the imported data
	Engine.get_main_loop().set_meta('current_save_lot', '/')
	
	# load the data
	Engine.get_main_loop().set_meta('definitions', data['definitions'])
	Engine.get_main_loop().set_meta('game_state', data['state'])
	Engine.get_main_loop().set_meta('last_dialog_state', data.get('dialog_state', null))
	set_current_timeline(get_saved_state_general_key('timeline'))


## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## 						DEFINITIONS
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# clears all variables
static func clear_all_variables():
	for d in _get_definitions()['variables']:
		d['value'] = ""

# sets the value of the value definition with the given name
static func set_variable(name: String, value):
	var exists = false
	
	if '/' in name:
		var variable_id = _get_variable_from_file_name(name)
		if variable_id != '':
			for d in _get_definitions()['variables']:
				if d['id'] == variable_id:
					d['value'] = str(value)
					exists = true
	else:		
		for d in _get_definitions()['variables']:
			if d['name'] == name:
				d['value'] = str(value)
				exists = true
	if exists == false:
		# TODO it would be great to automatically generate that missing variable here so they don't
		# have to create it from the editor. 
		print("[Dialogic] Warning! the variable [" + name + "] doesn't exists. Create it from the Dialogic editor.")
	return value

# returns the value of the value definition with the given name
static func get_variable(name: String, default = null):
	if '/' in name:
		var variable_id = _get_variable_from_file_name(name)
		for d in _get_definitions()['variables']:
			if d['id'] == variable_id:
				return d['value']
		print("[Dialogic] Warning! the variable [" + name + "] doesn't exists.")
		return default
	else:
		for d in _get_definitions()['variables']:
			if d['name'] == name:
				return d['value']
		print("[Dialogic] Warning! the variable [" + name + "] doesn't exists.")
		return default


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
	save('', true)


################################################################################
## 					HISTORY
################################################################################

# Used to toggle the history timeline display. Only useful if you do not wish to
# use the provided buttons
static func toggle_history():
	if has_current_dialog_node():
		var dialog_node = Engine.get_main_loop().get_meta('latest_dialogic_node')
		dialog_node.HistoryTimeline._on_toggle_history()
	else:
		print('[D] Tried to toggle history, but no dialog node exists.')


################################################################################
## 					COULD BE USED
################################################################################
# these are old things, that have little use.

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


# Returns a string with the action button set on the project settings
static func get_action_button():
	return DialogicResources.get_settings_value('input', 'default_action_key', 'dialogic_default_action')

################################################################################
## 					NOT TO BE USED FROM OUTSIDE
################################################################################
## this loads the saves definitions and returns the saves state_info ditionary
static func _load_from_slot(slot_name: String = '') -> Dictionary:
	Engine.get_main_loop().set_meta('definitions', DialogicResources.get_saved_definitions(slot_name))
	
	var state_info = DialogicResources.get_saved_state_info(slot_name)
	Engine.get_main_loop().set_meta('last_dialog_state', state_info.get('dialog_state', null))
	Engine.get_main_loop().set_meta('game_state', state_info.get('game_state', null))
	
	return state_info.get('dialog_state', {})


## this saves the current definitions and the given state info into the save folder @save_name
static func _save_state_and_definitions(save_name: String, state_info: Dictionary) -> void:
	DialogicResources.save_definitions(save_name, _get_definitions())
	DialogicResources.save_state_info(save_name, state_info)



static func _get_definitions() -> Dictionary:
	var definitions
	if Engine.get_main_loop().has_meta('definitions'):
		definitions = Engine.get_main_loop().get_meta('definitions')
	else:
		definitions = DialogicResources.get_default_definitions()
		Engine.get_main_loop().set_meta('definitions', definitions)
	return definitions


# used by the DialogNode
static func set_glossary_from_id(id: String, title: String, text: String, extra:String) -> void:
	var target_def: Dictionary;
	for d in _get_definitions()['glossary']:
		if d['id'] == id:
			target_def = d;
	if target_def != null:
		if title and title != "[No Change]":
			target_def['title'] = title
		if text and text != "[No Change]":
			target_def['text'] = text
		if extra and extra != "[No Change]":
			target_def['extra'] = extra

# used by the DialogNode
static func set_variable_from_id(id: String, value: String, operation: String) -> void:
	var target_def: Dictionary;
	for d in _get_definitions()['variables']:
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

# tries to find the path of a given timeline 
static func _get_timeline_file_from_name(timeline_name_path: String) -> String:
	var timelines = DialogicUtil.get_full_resource_folder_structure()['folders']['Timelines']
	
	# Checks for slash in the name, and uses the folder search if there is 
	if '/' in timeline_name_path:
		#Add leading slash if its a path and it is missing, for paths that have subfolders but no leading slash 
		if(timeline_name_path.left(1) != '/'):
			timeline_name_path = "/" + timeline_name_path
		var parts = timeline_name_path.split('/', false)
	
		# First check if it's a timeline in the root folder
		if parts.size() == 1:
			for t in DialogicUtil.get_timeline_list():
				for f in timelines['files']:
					if t['file'] == f && t['name'] == parts[0]:
						return t['file']
		if parts.size() > 1:
			var current_data
			var current_depth = 0
			for p in parts:
				if current_depth == 0:
					# Starting the crawl
					if (timelines['folders'].has(p) ):
						current_data = timelines['folders'][p]
					else:
						return ''
				elif current_depth == parts.size() - 1:
					# The final destination
					for t in DialogicUtil.get_timeline_list():
						for f in current_data['files']:
							if t['file'] == f && t['name'] == p:
								return t['file']
							
				else:
					# Still going deeper
					if (current_data['folders'].size() > 0):
						if p in current_data['folders']:
							current_data = current_data['folders'][p]
						else:
							return ''
					else:
						return ''
				current_depth += 1
		return ''
	else:
		# Searching for any timeline that could match that name
		for t in DialogicUtil.get_timeline_list():
			if t['name'] == timeline_name_path:
				return t['file']
	return ''

static func _get_variable_from_file_name(variable_name_path: String) -> String:
	#First add the leading slash if it is missing so algorithm works properly
	if(variable_name_path.left(1) != '/'):
		variable_name_path = "/" + variable_name_path

	var definitions = DialogicUtil.get_full_resource_folder_structure()['folders']['Definitions']
	var parts = variable_name_path.split('/', false)
	
	# Check the root if it's a variable in the root folder 
	if parts.size() == 1:
		for t in _get_definitions()['variables']:
			for f in definitions['files']:
				if t['id'] == f && t['name'] == parts[0]:
					return t['id']
	if parts.size() > 1:
		var current_data
		var current_depth = 0
		
		for p in parts:
			if current_depth == 0:

				# Starting the crawl
				if (definitions['folders'].has(p)):
					current_data = definitions['folders'][p]
				else:
					return ''
			elif current_depth == parts.size() - 1:
				# The final destination
				for t in _get_definitions()['variables']:
					for f in current_data['files']:
						if t['id'] == f && t['name'] == p:
							return t['id']
							
			else:
				# Still going deeper
				if (current_data['folders'].size() > 0):
					if p in current_data['folders']:
						current_data = current_data['folders'][p]
					else:
						return ''
				else:
					return ''
			current_depth += 1
	return ''
