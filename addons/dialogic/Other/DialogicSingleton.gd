extends Node

## This script is added as an AutoLoad when the plugin is activated
## It is used during game execution to access the dialogic resources

## Mainly it's used by the dialog_node.gd and the DialogicClass
## In your game you should consider using the methods of the DialogicClass!

var current_definitions := {}

#var current_state := {}
var autosave := true

var current_timeline := ''
var latest_dialog_node = null

var current_save_name := ""

## *****************************************************************************
##								INITIALIZATION
## *****************************************************************************

func _init() -> void:
	# Load saves on script init
	init(false)


func init(reset: bool=false) -> void:
	if reset and autosave:
		# Loads saved definitions into memory
		current_definitions = DialogicResources.get_default_definitions()
	else:
		# loads the default save slot first
		current_definitions = DialogicResources.get_saved_definitions()
	#current_state = DialogicResources.get_saved_state_info()


## *****************************************************************************
##							SAVING AND RESUMING
## *****************************************************************************

# this saves the current definitions and the given state info into the save folder @save_name
func save_state_and_definitions(save_name: String, state_info: Dictionary) -> void:
	DialogicResources.save_definitions(save_name, current_definitions)
	DialogicResources.save_state_info(save_name, state_info)


# this loads the saves definitions and returns the saves state_info ditionary
func resume_from_save(save_name: String) -> Dictionary:
	current_definitions = DialogicResources.get_saved_definitions(save_name)
	return DialogicResources.get_saved_state_info(save_name)


# this saves the current definitions to the given save folder @save_name 
func save_definitions_and_glossary(save_name:String) -> void:
	DialogicResources.save_definitions(save_name, current_definitions)


# this loads the saved defintiions from the folder @save_name into the current definitions
func load_definitions_and_glossary(save_name:String) -> void:
	current_definitions = DialogicResources.get_saved_definitions(save_name)

## *****************************************************************************
##						DEFINITIONS: VARIABLES/GLOSSARY
## *****************************************************************************

func get_definitions() -> Dictionary:
	return current_definitions


func get_definitions_list() -> Array:
	return DialogicDefinitionsUtil.definitions_json_to_array(current_definitions)


func get_default_definitions() -> Dictionary:
	return DialogicResources.get_default_definitions()


func get_default_definitions_list() -> Array:
	return DialogicDefinitionsUtil.definitions_json_to_array(get_default_definitions())


func save_definitions():
	if autosave:
		if latest_dialog_node:
			save_state_and_definitions(current_save_name, latest_dialog_node.get_current_state_info())
			
	else:
		return OK


func get_variable(name: String) -> String:
	for d in current_definitions['variables']:
		if d['name'] == name:
			return d['value']
	return ''


func set_variable(name: String, value) -> void:
	for d in current_definitions['variables']:
		if d['name'] == name:
			d['value'] = str(value)


func set_variable_from_id(id: String, value: String, operation: String) -> void:
	var target_def: Dictionary;
	for d in current_definitions['variables']:
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


func get_glossary(name: String) -> Dictionary:
	for d in current_definitions['glossary']:
		if d['name'] == name:
			return d
	return { 
		'title': '',
		'text': '',
		'extra': ''
	}


func set_glossary(name: String, title: String, text: String, extra: String) -> void:
	for d in current_definitions['glossary']:
		if d['name'] == name:
			d['title'] = title
			d['text'] = text
			d['extra'] = extra


func set_glossary_from_id(id: String, title: String, text: String, extra:String) -> void:
	var target_def: Dictionary;
	for d in current_definitions['glossary']:
		if d['id'] == id:
			target_def = d;
	if target_def != null:
		if title and title != "[No Change]":
			target_def['title'] = title
		if text and text != "[No Change]":
			target_def['text'] = text
		if extra and extra != "[No Change]":
			target_def['extra'] = extra


## *****************************************************************************
##								TIMELINES
## *****************************************************************************

func set_current_timeline(timeline: String):
	current_timeline = timeline


func get_current_timeline() -> String:
	return current_timeline


## *****************************************************************************
##								SAVE STATE
## *****************************************************************************

func save_state(save_name):
	pass

## *****************************************************************************
##								AUTOSAVE
## *****************************************************************************

func get_autosave() -> bool:
	return autosave;


func set_autosave(save: bool):
	autosave = save;


## *****************************************************************************
##								IMPORT/EXPORT
## *****************************************************************************
#
#func export() -> Dictionary:
#	return {
#		'definitions': current_definitions,
#		'state': current_state,
#	}
#
#func import(data: Dictionary) -> void:
#	init(false);
#	current_definitions = data['definitions'];
#	current_state = data['state'];
#	current_timeline = get_saved_state_general_key('timeline')
