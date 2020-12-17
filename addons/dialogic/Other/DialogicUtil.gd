tool
class_name DialogicUtil

static func test():
	print("Foo")


static func load_json(path):
	var file = File.new()
	if file.open(path, File.READ) != OK:
		file.close()
		return
	var data_text = file.get_as_text()
	file.close()
	var data_parse = JSON.parse(data_text)
	if data_parse.error != OK:
		return
	return data_parse.result


static func get_path(name, extra=''):
	var WORKING_DIR = "res://dialogic"
	var paths = {
		'WORKING_DIR': WORKING_DIR,
		'TIMELINE_DIR': WORKING_DIR + "/dialogs",
		'CHAR_DIR': WORKING_DIR + "/characters",
		'SETTINGS_FILE': WORKING_DIR + "/settings.json",
	}
	if extra != '':
		return paths[name] + '/' + extra
	else:
		return paths[name]

static func get_filename_from_path(path, extension = false):
	var file_name = path.split('/')[-1]
	if extension == false:
		file_name = file_name.split('.')[0]
	return file_name
