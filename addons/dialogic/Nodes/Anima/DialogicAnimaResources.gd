extends Node
class_name DialogicAnimaResources

const BASE_PATH := 'res://addons/dialogic/Nodes/Anima/animations/'

static func get_animation_script(animation_name: String):
#	for custom_animation in _custom_animations:
#		if custom_animation.name == animation_name:
#			return custom_animation.script

	var resource_file = get_animation_script_with_path(animation_name)
	if resource_file:
		return load(resource_file).new()

	printerr('No animation found with name: ', animation_name)

	return null


static func get_animation_script_with_path(animation_name: String) -> String:
	if not animation_name.ends_with('.gd'):
		animation_name += '.gd'

	animation_name = from_camel_to_snack_case(animation_name)

	for file_name in get_available_animations():
		if file_name is String and file_name.ends_with(animation_name):
			return file_name

	return ''


static func get_available_animations() -> Array:
	var list = _get_animations_list()
	var filtered := []

	for file in list:
		if file.find('.gd.') < 0:
			filtered.push_back(file.replace('.gdc', '.gd'))

	return filtered #+ _custom_animations


static func _get_animations_list() -> Array:
	var files = _get_scripts_in_dir(BASE_PATH)
	var filtered := []

	files.sort()
	return files

static func _get_scripts_in_dir(path: String, files: Array = []) -> Array:
	var dir = Directory.new()
	if dir.open(path) != OK:
		return files

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name != "." and file_name != "..":
			if dir.current_is_dir():
				_get_scripts_in_dir(path + file_name + '/', files)
			else:
				files.push_back(path + file_name)

		file_name = dir.get_next()

	return files

static func from_camel_to_snack_case(string:String) -> String:
	var result = PoolStringArray()
	var is_first_char = true

	for character in string:
		if character == character.to_lower() or is_first_char:
			result.append(character.to_lower())
		else:
			result.append('_' + character.to_lower())

		is_first_char = false

	return result.join('').replace(' ', '_')

