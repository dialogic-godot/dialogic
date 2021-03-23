extends Node

var current_definitions: Array
var default_definitions: Array


func init(reset: bool=false) -> void:
	# Loads saved definitions into memory
	DialogicResources.init_definitions_saves(reset)
	current_definitions = []
	var config = DialogicResources.get_saved_definitions_config()
	current_definitions = DialogicDefinitionsUtil.definitions_config_to_array(config)
	config = DialogicResources.get_default_definitions_config()
	default_definitions = DialogicDefinitionsUtil.definitions_config_to_array(config)


func get_definitions_list() -> Array:
	return current_definitions


func get_default_definitions_list() -> Array:
	return default_definitions


func save_definitions():
	var config = ConfigFile.new()
	for d in current_definitions:
		var s = d['section'];
		if d['type'] == 0:
			DialogicDefinitionsUtil.set_definition_variable(config, s, d['name'], d['value'])
		else:
			DialogicDefinitionsUtil.set_definition_glossary(config, s, d['name'], d['title'], d['text'], d['extra'])
	
	return DialogicResources.save_saved_definitions(config)


func get_variable(name: String) -> String:
	for d in current_definitions:
		if d['type'] == 0 and d['name'] == name:
			return d['value']
	return ''


func set_variable(name: String, value) -> void:
	for d in current_definitions:
		if d['type'] == 0 and d['name'] == name:
			d['value'] = str(value)


func set_variable_from_id(section: String, value) -> void:
	for d in current_definitions:
		if d['type'] == 0 and d['section'] == section:
			d['value'] = str(value)

func get_glossary(name: String) -> Dictionary:
	for d in current_definitions:
		if d['type'] == 1 and d['name'] == name:
			return d
	return { 
		'title': '',
		'text': '',
		'extra': ''
	}


func set_glossary(name: String, title: String, text: String, extra: String) -> void:
	for d in current_definitions:
		if d['type'] == 1 and d['name'] == name:
			d['title'] = title
			d['text'] = text
			d['extra'] = extra
