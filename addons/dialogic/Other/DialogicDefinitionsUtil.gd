extends Node
class_name DialogicDefinitionsUtil

static func get_definition_key(config: ConfigFile, section: String, key: String, default):
	if config.has_section(section):
		return config.get_value(section, key, default)
	else:
		return default


static func set_definition_variable(config: ConfigFile, section: String, name: String,  value):
	config.set_value(section, 'name', name)
	config.set_value(section, 'type', 0)
	config.set_value(section, 'value', str(value))


static func set_definition_glossary(config: ConfigFile, section: String, name: String,  extra_title: String,  extra_text: String,  extra_extra: String):
	config.set_value(section, 'name', name)
	config.set_value(section, 'type', 1)
	config.set_value(section, 'extra_title', extra_title)
	config.set_value(section, 'extra_text', extra_text)
	config.set_value(section, 'extra_extra', extra_extra)


static func add_definition_variable(config: ConfigFile, section: String, name: String, type: int, value):
	config.set_value(section, 'name', name)
	config.set_value(section, 'type', type)
	config.set_value(section, 'value', str(value))


static func delete_definition(config: ConfigFile, section: String):
	config.erase_section(section)


static func definitions_config_to_array(config: ConfigFile) -> Array:
	var array := []
	for section in config.get_sections():
		var type = config.get_value(section, 'type', 0);
		if type == 0:
			array.append({
				'section': section,
				'name': config.get_value(section, 'name', section),
				'value': config.get_value(section, 'value', ''),
				'type': type,
			})
		else:
			array.append({
				'section': section,
				'name': config.get_value(section, 'name', section),
				'title': config.get_value(section, 'extra_title', section),
				'text': config.get_value(section, 'extra_text', section),
				'extra': config.get_value(section, 'extra_extra', section),
				'type': type,
			})
	return array
