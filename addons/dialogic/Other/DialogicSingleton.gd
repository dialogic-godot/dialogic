extends Node

var running_id: String = ''


func generate_runtime_id(value: String = '') -> String:
	if value != '':
		running_id = value
		return running_id

	if running_id == '':
		# clear all the previous entries
		var directory = Directory.new()
		if directory.file_exists(DialogicUtil.get_path('DEFINITIONS_FILE')):
			var config = ConfigFile.new()
			config.load(DialogicUtil.get_path('DEFINITIONS_FILE'))
			for section in config.get_sections():
				for i in config.get_section_keys(section):
					if 'value-' in i:
						config.erase_section_key(section, i)
			config.save(DialogicUtil.get_path('DEFINITIONS_FILE'))
		# If the value is empty generate a new id and use that for this run
		running_id = DialogicUtil.generate_random_id()
	return running_id
