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
static func start(timeline: String, reset_saves: bool=true, dialog_scene_path: String="res://addons/dialogic/Dialog.tscn", debug_mode: bool=false, use_canvas_instead=true):
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
	
	var timelines = DialogicUtil.get_full_resource_folder_structure()['folders']['Timelines']
	var parts = timeline.split('/', false)
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
							dialog_node.timeline = t['file']
							return returned_dialog_node
			else:
				# Still going deeper
				current_data = current_data['folders'][p]
			current_depth += 1
	else:
		# Searching for any timeline that could match that name
		for t in DialogicUtil.get_timeline_list():
			if parts.size():
				if t['name'] == parts[0]:
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

	# Just in case everything else fails.
	return returned_dialog_node



## Same as the start method above, but using the last timeline saved.
## 
## @param timeline              The current timeline to load
## @param initial_timeline		The timeline to load in case no save is found.
## @param dialog_scene_path		If you made a custom Dialog scene or moved it from its default path, you can specify its new path here.
## @param debug_mode			Debug is disabled by default but can be enabled if needed.
## @returns						A Dialog node to be added into the scene tree.
static func start_from_save(timeline: String, initial_timeline: String, dialog_scene_path: String="res://addons/dialogic/Dialog.tscn", debug_mode: bool=false):
	var current = timeline
	if current.empty():
		current = initial_timeline
	return start(current, false, dialog_scene_path, debug_mode)

################################################################################
## 						BUILT-IN SAVING/LOADING
################################################################################


## Similar to the start function, but loads state info and definitions from a given save folder..
## 
## @param save_name		The name of the save folder.
##						Leaving this empty load from the default files.
## The other @params work like the ones in start()
static func resume_from_save(save_name: String, dialog_scene_path: String="res://addons/dialogic/Dialog.tscn", debug_mode: bool=false, use_canvas_instead=true) -> Node:
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

	dialog_node.resume_state_from_info(load_from_save(save_name))
	return returned_dialog_node


## Saves the current definitions and the latest added dialog nodes state info.
## 
## @param save_name		The name of the save folder. To load this save you have to specify the same
##						If the save folder doesn't exist it will be created. 
##						Leaving this empty will overwrite the default files.
static func save_current_state(save_name: String = '') -> void:
	if Engine.get_main_loop().has_meta('latest_dialogic_node') and is_instance_valid(Engine.get_main_loop().get_meta('latest_dialogic_node')):
		var save_data = Engine.get_main_loop().get_meta('latest_dialogic_node').get_current_state_info()
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


## this saves the current definitions and the given state info into the save folder @save_name
static func save_state_and_definitions(save_name: String, state_info: Dictionary) -> void:
	DialogicResources.save_definitions(save_name, get_definitions())
	DialogicResources.save_state_info(save_name, state_info)


## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## 						EXPORT / IMPORT
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#func get_saved_state_general_key(key: String) -> String:
#	if key in current_state['general'].keys():
#		return current_state['general'][key]
#	else:
#		return ''
#
#
#func set_saved_state_general_key(key: String, value) -> void:
#	current_state['general'][key] = str(value)
#	save_state()
#
#func save_state():
#	if autosave:
#		return DialogicResources.save_saved_state_config(current_state)
#	else:
#		return OK

static func export(dialog_node = null):
#	if dialog_node == null and has_current_dialog_node():
#		dialog_node = Engine.get_main_loop().get_meta('latest_dialogic_node')
#
#	return {
#		'definitions': get_definitions(),
#		'state': current_state,
#	}
	pass

static func import():
#	init(false);
#	current_definitions = data['definitions'];
#	current_state = data['state'];
#	current_timeline = get_saved_state_general_key('timeline')
	pass


################################################################################
## 					NOT TO BE USED FROM OUTSIDE
################################################################################

#
## this loads the saves definitions and returns the saves state_info ditionary
static func load_from_save(save_name: String) -> Dictionary:
	Engine.get_main_loop().set_meta('definitions', DialogicResources.get_saved_definitions(save_name))
	return DialogicResources.get_saved_state_info(save_name)

## Will save the current definition and glossary values into the save folder with the given name.
## 
## @param save_name		The name of the save folder.
static func save_defintions_and_glossary(save_name:String) -> void:
	DialogicResources.save_definitions(save_name, Engine.get_main_loop().get_meta('definitions'))


## Will load the defintiion and glossary values saved in the save folder @save_name.
## 
## @param save_name		The name of the save folder.
static func load_definitions_and_glossary(save_name:String) -> void:
	Engine.get_main_loop().set_meta('definitions', DialogicResources.get_saved_definitions(save_name))


static func has_current_dialog_node() -> bool:
	return Engine.get_main_loop().has_meta('latest_dialogic_node') and is_instance_valid(Engine.get_main_loop().get_meta('latest_dialogic_node'))


# --------------------------------------------------------------------------------------------------
# The following functions existed previously on the DialogicSingleton.gd singleton.
# I removed that one and moved the functions here.


static func absolute_root():
	var main_loop = Engine.get_main_loop()
	return main_loop


static func set_current_timeline(timeline):
	absolute_root().set_meta('current_timeline', timeline)
	return timeline


static func get_current_timeline():
	var timeline
	timeline = absolute_root().get_meta('current_timeline')
	if timeline == null:
		timeline = ''
	return timeline


static func get_definitions() -> Dictionary:
	var metalist = absolute_root().get_meta_list()
	var definitions
	if 'definitions' in metalist:
		definitions = absolute_root().get_meta('definitions')
	else:
		definitions = DialogicResources.get_default_definitions()
		absolute_root().set_meta('definitions', definitions)
	return definitions


static func set_variable(name: String, value):
	for d in get_definitions()['variables']:
		if d['name'] == name:
			d['value'] = str(value)


static func get_variable(name: String, default = null):
	for d in get_definitions()['variables']:
		if d['name'] == name:
			return d['value']
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


static func save_definitions(autosave = true):
	if autosave:
		return DialogicResources.save_saved_definitions(get_definitions())
	else:
		return OK

	
