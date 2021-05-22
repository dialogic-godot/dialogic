extends Node
class_name DialogicDefinitionsUtil

## This class handles definitions
# It is used by the DialogicSingleton, the DialogicResource class and the DialogicUtil class

static func get_definition_by_key(data: Dictionary, key: String, value: String):
	var variables : Array = data['variables']
	var glossary : Array = data['glossary']
	for v in variables:
		if v[key] == value:
			return v
	for g in glossary:
		if g[key] == value:
			return g
	return null


static func get_definition_by_id(data: Dictionary, id: String):
	return get_definition_by_key(data, 'id', id)


static func get_definition_by_name(data: Dictionary, id: String):
	return get_definition_by_key(data, 'name', id)


static func set_definition(section: String, data: Dictionary, elem: Dictionary):
	delete_definition(data, elem['id'])
	var array: Array = data[section]
	var found = false;
	for e in array:
		if e['id'] == elem['id']:
			found = true
			array.erase(e)
			array.append(elem)
			break
	if not found:
		array.append(elem)


static func set_definition_variable(data: Dictionary, id: String, name: String, value):
	set_definition('variables', data, {
		'id': id,
		'name': name,
		'value': value,
		'type': 0
	})


static func set_definition_glossary(data: Dictionary, id: String, name: String,  title: String,  text: String,  extra: String):
	set_definition('glossary', data, {
		'id': id,
		'name': name,
		'title': title,
		'text': text,
		'extra': extra,
		'type': 1
	})


static func delete_definition(data: Dictionary, id: String):
	var variables : Array = data['variables']
	var glossary : Array = data['glossary']
	var item = get_definition_by_id(data, id);
	if item != null:
		if (item['type'] == 0):
			variables.erase(item)
		else:
			glossary.erase(item)


static func definitions_json_to_array(data: Dictionary) -> Array:
	return data['variables'] + data['glossary']
