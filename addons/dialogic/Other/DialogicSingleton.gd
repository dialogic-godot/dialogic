extends Node

var current_definitions := {}
var default_definitions := {}

var current_timeline := ''

func _init() -> void:
	init(false)


func init(reset: bool=false) -> void:
	# Loads saved definitions into memory
	DialogicResources.init_saves(reset)
	current_definitions = DialogicResources.get_saved_definitions()
	default_definitions = DialogicResources.get_default_definitions()
	current_timeline = DialogicResources.get_saved_state_general_key('timeline')


func get_definitions_list() -> Array:
	return DialogicDefinitionsUtil.definitions_json_to_array(current_definitions)


func get_definitions() -> Dictionary:
	return current_definitions


func get_default_definitions() -> Dictionary:
	return default_definitions


func get_default_definitions_list() -> Array:
	return DialogicDefinitionsUtil.definitions_json_to_array(default_definitions)


func save_definitions():
	return DialogicResources.save_saved_definitions(current_definitions)


func get_variable(name: String) -> String:
	for d in current_definitions['variables']:
		if d['name'] == name:
			return d['value']
	return ''


func set_variable(name: String, value) -> void:
	for d in current_definitions['variables']:
		if d['name'] == name:
			d['value'] = str(value)


func set_variable_from_id(id: String, value) -> void:
	for d in current_definitions['variables']:
		if d['id'] == id:
			d['value'] = str(value)


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


func set_current_timeline(timeline: String):
	current_timeline = timeline
	DialogicResources.set_saved_state_general_key('timeline', timeline)


func get_current_timeline() -> String:
	return current_timeline


