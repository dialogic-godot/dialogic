tool
class_name DialogicUtil

static func get_editor_scale(ref) -> float:
	# There hasn't been a proper way of reliably getting the editor scale
	# so this function aims at fixing that by identifying what the scale is and
	# returning a value to use as a multiplier for manual UI tweaks
	
	# The way of getting the scale could change, but this is the most reliable
	# solution I could find that works in many different computer/monitors.
	var _scale = ref.get_constant("inspector_margin", "Editor")
	_scale = _scale * 0.125
	
	return _scale


static func listdir(path: String) -> Array:
	# https://docs.godotengine.org/en/stable/classes/class_directory.html#description
	var files: Array = []
	var dir := Directory.new()
	var err = dir.open(path)
	if err == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and not file_name.begins_with("."):
				files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("[Dialogic] Error while accessing path " + path + " - Error: " + str(err))
	return files


static func get_dialogic_plugin() -> Node:
	var tree: SceneTree = Engine.get_main_loop()
	return tree.get_root().get_node('EditorNode/DialogicPlugin')



static func list_resources_of_type(extension):
	var all_resources = scan_folder('res://', extension)
	return all_resources

static func scan_folder(folder_path:String, extension:String):
	var dir = Directory.new()
	var list = []
	if dir.open(folder_path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				list += scan_folder(folder_path+"/"+file_name, extension)
			else:
				if file_name.ends_with(extension):
					list.append(folder_path+"/"+file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	return list

static func guess_resource(extension, identifier):
	var resources = list_resources_of_type(extension)
	for resource_path in resources:
		if resource_path.get_file().trim_suffix(extension) == identifier:
			return resource_path


static func get_event_by_string(string:String) -> Resource:
	for event in [ # the text event should always be last. 
		# Every event that isn't identified as something else, will end up as text
		# We should get this list from a folder or something, but then we'll have to sort it somehow
		"res://addons/dialogic/Resources/Events/event_condition.gd",
		"res://addons/dialogic/Resources/Events/event_end_branch.gd",
		"res://addons/dialogic/Resources/Events/event_choice.gd",
		"res://addons/dialogic/Resources/Events/event_character.gd",
		"res://addons/dialogic/Resources/Events/event_comment.gd",
		"res://addons/dialogic/Resources/Events/event_text.gd"
	]:
		if load(event).is_valid_event_string(string):
			return load(event)
	return load("res://addons/dialogic/Resources/Events/event_text.gd")


# RENABLE IF REALLY NEEDED, OTHERWISE DELETE BEFORE RELEASE 
#static func list_to_dict(list):
#	var dict := {}
#	for val in list:
#		dict[val["file"]] = val
#	return dict

# RENABLE IF REALLY NEEDED, OTHERWISE DELETE BEFORE RELEASE 
#static func beautify_filename(animation_name: String) -> String:
#	if animation_name == '[Default]' or animation_name == '[No Animation]':
#		return animation_name
#	var a_string = animation_name.get_file().trim_suffix('.gd')
#	if '-' in a_string:
#		a_string = a_string.split('-')[1].capitalize()
#	else:
#		a_string = a_string.capitalize()
#	return a_string

# RENABLE IF REALLY NEEDED, OTHERWISE DELETE BEFORE RELEASE
#static func compare_dicts(dict_1: Dictionary, dict_2: Dictionary) -> bool:
#	# I tried using the .hash() function but it was returning different numbers
#	# even when the dictionary was exactly the same.
#	if str(dict_1) != "Null" and str(dict_2) != "Null":
#		if str(dict_1) == str(dict_2):
#			return true
#	return false
