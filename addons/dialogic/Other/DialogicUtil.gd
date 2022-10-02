@tool
class_name DialogicUtil

static func get_editor_scale() -> float:
	return get_dialogic_plugin().editor_interface.get_editor_scale()


static func listdir(path: String, files_only: bool = true, throw_error:bool = true, full_file_path:bool = false) -> Array:
	var files: Array = []
	if DirAccess.dir_exists_absolute(path):
		var dir := DirAccess.open(path)
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not file_name.begins_with("."):
				if files_only:
					if not dir.current_is_dir() and not file_name.ends_with('.import'):
						if full_file_path:
							files.append(path.path_join(file_name))
						else:
							files.append(file_name)
				else:
					if full_file_path:
						files.append(path.path_join(file_name))
					else:
						files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	return files


static func get_dialogic_plugin() -> Node:
	var tree: SceneTree = Engine.get_main_loop()
	return tree.get_root().get_child(0).get_node('DialogicPlugin')


static func list_resources_of_type(extension):
	var all_resources = scan_folder('res://', extension)
	return all_resources


static func scan_folder(path:String, extension:String) -> Array:
	var list: Array = []
	if DirAccess.dir_exists_absolute(path):
		var dir := DirAccess.open(path)
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				list += scan_folder(path + "/" + file_name, extension)
			else:
				if file_name.ends_with(extension):
					list.append(path + "/" + file_name)
			file_name = dir.get_next()
	return list


static func guess_resource(extension, identifier):
	var resources = list_resources_of_type(extension)
	for resource_path in resources:
		if resource_path.get_file().trim_suffix(extension) == identifier:
			return resource_path


static func get_event_by_string(string:String) -> Resource:
	var event_scripts = get_event_scripts()
	
	# move the text event to the end of the list as it's the default.
	event_scripts.erase("res://addons/dialogic/Events/Text/event.gd")
	event_scripts.append("res://addons/dialogic/Events/Text/event.gd")
	
	for event in event_scripts:
		if load(event).new()._test_event_string(string):

			return load(event)
	return load("res://addons/dialogic/Events/Text/event.gd")


static func get_project_setting(setting:String, default = null):
	return ProjectSettings.get_setting(setting) if ProjectSettings.has_setting(setting) else default


static func get_event_scripts(include_custom_events:bool = true) -> Array:
	var event_scripts = []
	
	var file_list = listdir("res://addons/dialogic/Events/", false)
	for file in file_list:
		var possible_script:String = "res://addons/dialogic/Events/" + file + "/event.gd"
		if FileAccess.file_exists(possible_script):
			event_scripts.append(possible_script)
	
	if include_custom_events:
		file_list = listdir("res://addons/dialogic_additions/Events/", false, false)
		for file in file_list:
			var possible_script: String = "res://addons/dialogic_additions/Events/" + file + "/event.gd"
			if FileAccess.file_exists(possible_script):
				event_scripts.append(possible_script)
		
	return event_scripts


static func pretty_name(script:String) -> String:
	var _name = script.get_file().trim_suffix("."+script.get_extension())
	_name = _name.replace('_', ' ')
	_name = _name.capitalize()
	return _name


static func str_to_bool(boolstring:String) -> bool:
	return true if boolstring == "true" else false


static func logical_convert(value):
	if typeof(value) == TYPE_STRING:
		if value.is_valid_int():
			return value.to_int()
		if value.is_valid_float():
			return value.to_float()
		if value == 'true':
			return true
		if value == 'false':
			return false
	return value


static func get_color_palette(default:bool = false) -> Dictionary:
	# Colors are using the ProjectSettings instead of the EditorSettings
	# because there is a bug in Godot which prevents us from using it.
	# When you try to do it, the text in the timelines goes to weird artifacts
	# and on the Output panel you see the error:
	#  ./core/rid.h:151 - Condition "!id_map.has(p_rid.get_data())" is true. Returned: nullptr
	# over and over again.
	# Might revisit this in Godot 4, but don't have any high hopes for it improving.
	var colors = [
		Color('#3b8bf2'), # Blue
		Color('#00b15f'), # Green
		Color('#9468e8'), # Purple
		Color('#de5c5c'), # Red
		Color('#fa952a'), # Orange
		Color('#7C7C7C')  # Gray
	]
	var color_dict = {}
	var index = 1
	for n in colors:
		var color_name = 'Color' + str(index)
		color_dict[color_name] = n
		if !default:
			if ProjectSettings.has_setting('dialogic/editor/' + color_name):
				color_dict[color_name] = ProjectSettings.get_setting('dialogic/editor/' + color_name)
		index += 1
	
	return color_dict


static func get_color(value:String) -> Color:
	var colors = get_color_palette()
	return colors[value]


static func is_physics_timer()->bool:
	return get_project_setting('dialogic/timer/process_in_physics', false)
	

static func update_timer_process_callback(timer:Timer) -> void:
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS if is_physics_timer() else Timer.TIMER_PROCESS_IDLE
