@tool
class_name DialogicUtil

## Script that container helper methods for both editor and game execution.
## Used whenever the same thing is needed in different parts of the plugin.
 

################################################################################
##					EDITOR
################################################################################
static func get_editor_scale() -> float:
	return get_dialogic_plugin().get_editor_interface().get_editor_scale()


static func get_dialogic_plugin() -> Node:
	var tree: SceneTree = Engine.get_main_loop()
	if tree.get_root().get_child(0).has_node('DialogicPlugin'):
		return tree.get_root().get_child(0).get_node('DialogicPlugin')
	return null



################################################################################
##					FILE SYSTEM
################################################################################
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


static func list_resources_of_type(extension:String) -> Array:
	var all_resources := scan_folder('res://', extension)
	return all_resources


static func scan_folder(path:String, extension:String) -> Array:
	var list: Array = []
	if DirAccess.dir_exists_absolute(path):
		var dir := DirAccess.open(path)
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				list += scan_folder(path.path_join(file_name), extension)
			else:
				if file_name.ends_with(extension):
					list.append(path.path_join(file_name))
			file_name = dir.get_next()
	return list


static func guess_resource(extension, identifier):
	var resources = list_resources_of_type(extension)
	for resource_path in resources:
		if resource_path.get_file().trim_suffix(extension) == identifier:
			return resource_path


## TODO remove this since ProjectSetting.get_setting supports default arg now.
static func get_project_setting(setting:String, default = null):
	return ProjectSettings.get_setting(setting) if ProjectSettings.has_setting(setting) else default


static func get_indexers(include_custom := true, force_reload := false) -> Array[DialogicIndexer]:
	if Engine.get_main_loop().has_meta('dialogic_indexers') and !force_reload:
		return Engine.get_main_loop().get_meta('dialogic_indexers')
	
	var indexers : Array[DialogicIndexer] = []
	
	for file in listdir("res://addons/dialogic/Events/", false):
		var possible_script:String = "res://addons/dialogic/Events/" + file + "/index.gd"
		if FileAccess.file_exists(possible_script):
			indexers.append(load(possible_script).new())
	
	if include_custom:
		var extensions_folder :String= ProjectSettings.get_setting('dialogic/extension_folder/', "res://addons/dialogic_additions/")
		for file in listdir(extensions_folder, false, false):
			var possible_script: String = extensions_folder.path_join(file + "/index.gd")
			if FileAccess.file_exists(possible_script):
				indexers.append(load(possible_script).new())
	
	Engine.get_main_loop().set_meta('dialogic_indexers', indexers)
	return indexers


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


static func get_next_translation_id() -> String:
	ProjectSettings.set_setting('dialogic/translation/id_counter', get_project_setting('dialogic/translation/id_counter', 16)+1)
	return '%x' % get_project_setting('dialogic/translation/id_counter', 16)


# helper that converts a nested variable dictionary into an array with paths
static func list_variables(dict:Dictionary, path := "") -> Array:
	var array := []
	for key in dict.keys():
		if typeof(dict[key]) == TYPE_DICTIONARY:
			array.append_array(list_variables(dict[key], path+key+"."))
		else:
			array.append(path+key)
	return array


static func get_default_layout() -> String:
	return "res://addons/dialogic/Events/DefaultLayouts/Default/DialogicDefaultLayout.tscn"


static func apply_scene_export_overrides(node:Node, export_overrides:Dictionary) -> void:
	for i in export_overrides:
		if i in node:
			node.set(i, str_to_var(export_overrides[i]))

static func setup_script_property_edit_node(property_info: Dictionary, value:Variant, methods:Dictionary) -> Control:
	var input :Control = null
	match property_info['type']:
		TYPE_BOOL:
			input = CheckBox.new()
			if value != null:
				input.button_pressed = value
			input.toggled.connect(methods.get('bool').bind(property_info['name']))
		TYPE_COLOR:
			input = ColorPickerButton.new()
			if value != null:
				input.color = value
			input.color_changed.connect(methods.get('color').bind(property_info['name']))
			input.custom_minimum_size.x = DialogicUtil.get_editor_scale()*50
		TYPE_INT:
			if property_info['hint'] & PROPERTY_HINT_ENUM:
				input = OptionButton.new()
				for x in property_info['hint_string'].split(','):
					input.add_item(x.split(':')[0])
				if value != null:
					input.select(value)
				input.item_selected.connect(methods.get('enum').bind(property_info['name']))
			else:
				input = SpinBox.new()
				input.value_changed.connect(methods.get('int').bind(property_info['name']))
				input.step = 1
				if value != null:
					input.value = value
		TYPE_FLOAT:
			input = SpinBox.new()
			input.value_changed.connect(methods.get('float').bind(property_info['name']))
			if value != null:
				input.value = value
		TYPE_STRING:
			if property_info['hint'] & PROPERTY_HINT_ENUM:
				input = OptionButton.new()
				var options :PackedStringArray = []  
				for x in property_info['hint_string'].split(','):
					options.append(x.split(':')[0].strip_edges())
					input.add_item(options[-1])
				if value != null:
					input.select(options.find(value))
				input.item_selected.connect(methods.get('string_enum').bind(property_info['name'], options))
			elif property_info['hint'] & PROPERTY_HINT_FILE:
				input = load("res://addons/dialogic/Editor/Events/Fields/FilePicker.tscn").instantiate()
				input.file_filter = property_info['hint_string']
				input.property_name = property_info['name']
				input.placeholder = "Default"
				input.hide_reset = true
				if value != null:
					input.set_value(value)
				input.value_changed.connect(methods.get('file'))
			else:
				input = LineEdit.new()
				if value != null:
					input.text = value
				input.text_submitted.connect(methods.get('string').bind(property_info['name']))
		_:
			input = LineEdit.new()
			if value != null:
				input.text = value
			input.text_submitted.connect(methods.get('string').bind(property_info['name']))
	return input
