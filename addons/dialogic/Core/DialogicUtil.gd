@tool
class_name DialogicUtil

## Script that container helper methods for both editor and game execution.
## Used whenever the same thing is needed in different parts of the plugin.

#region EDITOR
################################################################################
static func get_editor_scale() -> float:
	return get_dialogic_plugin().get_editor_interface().get_editor_scale()


## Although this does in fact always return a EditorPlugin node,
##  that class is apparently not present in export and referencing it here creates a crash.
static func get_dialogic_plugin() -> Node:
	for child in Engine.get_main_loop().get_root().get_children():
		if child.get_class() == "EditorNode":
			return child.get_node('DialogicPlugin')
	return null

#endregion


## Returns the autoload when in-game.
static func autoload() -> DialogicGameHandler:
	if Engine.is_editor_hint():
		return null
	if not Engine.get_main_loop().root.has_node("Dialogic"):
		return null
	return Engine.get_main_loop().root.get_node("Dialogic")


#region FILE SYSTEM
################################################################################
static func listdir(path: String, files_only:= true, throw_error:= true, full_file_path:= false, include_imports := false) -> Array:
	var files: Array = []
	if path.is_empty(): path = "res://"
	if DirAccess.dir_exists_absolute(path):
		var dir := DirAccess.open(path)
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not file_name.begins_with("."):
				if files_only:
					if not dir.current_is_dir() and (not file_name.ends_with('.import') or include_imports):
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



static func get_module_path(name:String, builtin:=true) -> String:
	if builtin:
		return "res://addons/dialogic/Modules".path_join(name)
	else:
		return ProjectSettings.get_setting('dialogic/extensions_folder', 'res://addons/dialogic_additions').path_join(name)


static func update_autoload_subsystem_access() -> void:
	var script: Script = load("res://addons/dialogic/Core/DialogicGameHandler.gd")

	var new_subsystem_access_list := "#region SUBSYSTEMS\n"

	for indexer in get_indexers():
		for subsystem in indexer._get_subsystems().duplicate(true):
			new_subsystem_access_list += '\nvar {name} := preload("{script}").new():\n\tget: return get_subsystem("{name}")\n'.format(subsystem)

	new_subsystem_access_list += "\n#endregion"

	script.source_code = RegEx.create_from_string("#region SUBSYSTEMS\\n#*\\n((?!#endregion)(.*\\n))*#endregion").sub(script.source_code, new_subsystem_access_list)
	ResourceSaver.save(script)


static func get_indexers(include_custom := true, force_reload := false) -> Array[DialogicIndexer]:
	if Engine.get_main_loop().has_meta('dialogic_indexers') and !force_reload:
		return Engine.get_main_loop().get_meta('dialogic_indexers')

	var indexers: Array[DialogicIndexer] = []

	for file in listdir(DialogicUtil.get_module_path(''), false):
		var possible_script: String = DialogicUtil.get_module_path(file).path_join("index.gd")
		if FileAccess.file_exists(possible_script):
			indexers.append(load(possible_script).new())

	if include_custom:
		var extensions_folder: String = ProjectSettings.get_setting('dialogic/extensions_folder', "res://addons/dialogic_additions/")
		for file in listdir(extensions_folder, false, false):
			var possible_script: String = extensions_folder.path_join(file + "/index.gd")
			if FileAccess.file_exists(possible_script):
				indexers.append(load(possible_script).new())

	Engine.get_main_loop().set_meta('dialogic_indexers', indexers)
	return indexers


enum AnimationType {ALL, IN, OUT, ACTION}
static func get_portrait_animation_scripts(type:=AnimationType.ALL, include_custom:=true) -> Array:
	var animations := DialogicResourceUtil.list_special_resources_of_type("PortraitAnimation")

	return animations.filter(
		func(script):
			if type == AnimationType.ALL: return true;
			if type == AnimationType.IN: return '_in' in script;
			if type == AnimationType.OUT: return '_out' in script;
			if type == AnimationType.ACTION: return not ('_in' in script or '_out' in script))


static func pretty_name(script:String) -> String:
	var _name := script.get_file().trim_suffix("."+script.get_extension())
	_name = _name.replace('_', ' ')
	_name = _name.capitalize()
	return _name


#endregion


#region EDITOR SETTINGS & COLORS
################################################################################

static func set_editor_setting(setting:String, value:Variant) -> void:
	var cfg := ConfigFile.new()
	if FileAccess.file_exists('user://dialogic/editor_settings.cfg'):
		cfg.load('user://dialogic/editor_settings.cfg')

	cfg.set_value('DES', setting, value)

	if !DirAccess.dir_exists_absolute('user://dialogic'):
		DirAccess.make_dir_absolute('user://dialogic')
	cfg.save('user://dialogic/editor_settings.cfg')


static func get_editor_setting(setting:String, default:Variant=null) -> Variant:
	var cfg := ConfigFile.new()
	if !FileAccess.file_exists('user://dialogic/editor_settings.cfg'):
		return default

	if !cfg.load('user://dialogic/editor_settings.cfg') == OK:
		return default

	return cfg.get_value('DES', setting, default)


static func get_color_palette(default:bool = false) -> Dictionary:
	var defaults := {
		'Color1': Color('#3b8bf2'), # Blue
		'Color2': Color('#00b15f'), # Green
		'Color3': Color('#e868e2'), # Pink
		'Color4': Color('#9468e8'), # Purple
		'Color5': Color('#574fb0'), # DarkPurple
		'Color6': Color('#1fa3a3'), # Aquamarine
		'Color7': Color('#fa952a'), # Orange
		'Color8': Color('#de5c5c'), # Red
		'Color9': Color('#7c7c7c'), # Gray
	}
	if default:
		return defaults
	return get_editor_setting('color_palette', defaults)


static func get_color(value:String) -> Color:
	var colors := get_color_palette()
	return colors[value]

#endregion


#region TIMER PROCESS MODE
################################################################################
static func is_physics_timer() -> bool:
	return ProjectSettings.get_setting('dialogic/timer/process_in_physics', false)


static func update_timer_process_callback(timer:Timer) -> void:
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS if is_physics_timer() else Timer.TIMER_PROCESS_IDLE

#endregion


#region TRANSLATIONS
################################################################################

static func get_next_translation_id() -> String:
	ProjectSettings.set_setting('dialogic/translation/id_counter', ProjectSettings.get_setting('dialogic/translation/id_counter', 16)+1)
	return '%x' % ProjectSettings.get_setting('dialogic/translation/id_counter', 16)

#endregion


#region VARIABLES
################################################################################

enum VarTypes {ANY, STRING, FLOAT, INT, BOOL}


static func get_default_variables() -> Dictionary:
	return ProjectSettings.get_setting('dialogic/variables', {})


# helper that converts a nested variable dictionary into an array with paths
static func list_variables(dict:Dictionary, path := "", type:=VarTypes.ANY) -> Array:
	var array := []
	for key in dict.keys():
		if typeof(dict[key]) == TYPE_DICTIONARY:
			array.append_array(list_variables(dict[key], path+key+".", type))
		else:
			if type == VarTypes.ANY or get_variable_value_type(dict[key]) == type:
				array.append(path+key)
	return array


static func get_variable_value_type(value:Variant) -> int:
	match typeof(value):
		TYPE_STRING:
			return VarTypes.STRING
		TYPE_FLOAT:
			return VarTypes.FLOAT
		TYPE_INT:
			return VarTypes.INT
		TYPE_BOOL:
			return VarTypes.BOOL
	return VarTypes.ANY


static func get_variable_type(path:String, dict:Dictionary={}) -> VarTypes:
	if dict.is_empty():
		dict = get_default_variables()
	return get_variable_value_type(_get_value_in_dictionary(path, dict))


## This will set a value in a dictionary (or a sub-dictionary based on the path)
## e.g. it could set "Something.Something.Something" in {'Something':{'Something':{'Someting':"value"}}}
static func _set_value_in_dictionary(path:String, dictionary:Dictionary, value):
	if '.' in path:
		var from := path.split('.')[0]
		if from in dictionary.keys():
			dictionary[from] = _set_value_in_dictionary(path.trim_prefix(from+"."), dictionary[from], value)
	else:
		if path in dictionary.keys():
			dictionary[path] = value
	return dictionary


## This will get a value in a dictionary (or a sub-dictionary based on the path)
## e.g. it could get "Something.Something.Something" in {'Something':{'Something':{'Someting':"value"}}}
static func _get_value_in_dictionary(path:String, dictionary:Dictionary, default= null) -> Variant:
	if '.' in path:
		var from := path.split('.')[0]
		if from in dictionary.keys():
			return _get_value_in_dictionary(path.trim_prefix(from+"."), dictionary[from], default)
	else:
		if path in dictionary.keys():
			return dictionary[path]
	return default

#endregion



#region STYLES
################################################################################

static func get_default_layout_base() -> PackedScene:
	return load(DialogicUtil.get_module_path('DefaultLayoutParts').path_join("Base_Default/default_layout_base.tscn"))


static func get_fallback_style() -> DialogicStyle:
	return load(DialogicUtil.get_module_path('DefaultLayoutParts').path_join("Style_VN_Default/default_vn_style.tres"))


static func get_default_style() -> DialogicStyle:
	var default: String = ProjectSettings.get_setting('dialogic/layout/default_style', '')
	if !ResourceLoader.exists(default):
		return get_fallback_style()
	return load(default)


static func get_style_by_name(name:String) -> DialogicStyle:
	if name.is_empty():
		return get_default_style()

	var styles: Array = ProjectSettings.get_setting('dialogic/layout/style_list', [])
	for style in styles:
		if not ResourceLoader.exists(style):
			continue
		if load(style).name == name:
			return load(style)

	return get_default_style()
#endregion


#region SCENE EXPORT OVERRIDES
################################################################################

static func apply_scene_export_overrides(node:Node, export_overrides:Dictionary, apply := true) -> void:
	var default_info := get_scene_export_defaults(node)
	if !node.script:
		return
	var property_info: Array[Dictionary] = node.script.get_script_property_list()
	for i in property_info:
		if i['usage'] & PROPERTY_USAGE_EDITOR:
			if i['name'] in export_overrides:
				if str_to_var(export_overrides[i['name']]) == null and typeof(node.get(i['name'])) == TYPE_STRING:
					node.set(i['name'], export_overrides[i['name']])
				else:
					node.set(i['name'], str_to_var(export_overrides[i['name']]))
			elif i['name'] in default_info:
				node.set(i['name'], default_info.get(i['name']))
	if apply:
		if node.has_method('apply_export_overrides'):
			node.apply_export_overrides()


static func get_scene_export_defaults(node:Node) -> Dictionary:
	if !node.script:
		return {}

	if Engine.get_main_loop().has_meta('dialogic_scene_export_defaults') and \
			node.script.resource_path in Engine.get_main_loop().get_meta('dialogic_scene_export_defaults'):
		return Engine.get_main_loop().get_meta('dialogic_scene_export_defaults')[node.script.resource_path]

	if !Engine.get_main_loop().has_meta('dialogic_scene_export_defaults'):
		Engine.get_main_loop().set_meta('dialogic_scene_export_defaults', {})
	var defaults := {}
	var property_info :Array[Dictionary] = node.script.get_script_property_list()
	for i in property_info:
		if i['usage'] & PROPERTY_USAGE_EDITOR:
			defaults[i['name']] = node.get(i['name'])
	Engine.get_main_loop().get_meta('dialogic_scene_export_defaults')[node.script.resource_path] = defaults
	return defaults

#endregion


#region INSPECTOR FIELDS
################################################################################

static func setup_script_property_edit_node(property_info: Dictionary, value:Variant, property_changed:Callable) -> Control:
	var input: Control = null
	match property_info['type']:
		TYPE_BOOL:
			input = CheckBox.new()
			if value != null:
				input.button_pressed = value
			input.toggled.connect(DialogicUtil._on_export_bool_submitted.bind(property_info.name, property_changed))
		TYPE_COLOR:
			input = ColorPickerButton.new()
			if value != null:
				input.color = value
			input.color_changed.connect(DialogicUtil._on_export_color_submitted.bind(property_info.name, property_changed))
			input.custom_minimum_size.x = DialogicUtil.get_editor_scale()*50
		TYPE_INT:
			if property_info['hint'] & PROPERTY_HINT_ENUM:
				input = OptionButton.new()
				for x in property_info['hint_string'].split(','):
					input.add_item(x.split(':')[0])
				if value != null:
					input.select(value)
				input.item_selected.connect(DialogicUtil._on_export_int_enum_submitted.bind(property_info.name, property_changed))
			else:
				input = SpinBox.new()
				input.value_changed.connect(DialogicUtil._on_export_number_submitted.bind(property_info.name, property_changed))
				if property_info.hint_string == 'int':
					input.step = 1
					input.allow_greater = true
					input.allow_lesser = true
				elif ',' in property_info.hint_string:
					input.min_value = int(property_info.hint_string.get_slice(',', 0))
					input.max_value = int(property_info.hint_string.get_slice(',', 1))
					if property_info.hint_string.count(',') > 1:
						input.step = int(property_info.hint_string.get_slice(',', 2))
				if value != null:
					input.value = value
		TYPE_FLOAT:
			input = SpinBox.new()
			input.step = 0.01
			if ',' in property_info.hint_string:
				input.min_value = float(property_info.hint_string.get_slice(',', 0))
				input.max_value = float(property_info.hint_string.get_slice(',', 1))
				if property_info.hint_string.count(',') > 1:
					input.step = float(property_info.hint_string.get_slice(',', 2))
			input.value_changed.connect(DialogicUtil._on_export_number_submitted.bind(property_info.name, property_changed))
			if value != null:
				input.value = value
		TYPE_VECTOR2:
			input = load("res://addons/dialogic/Editor/Events/Fields/field_vector2.tscn").instantiate()
			input.set_value(value)
			input.property_name = property_info['name']
			input.value_changed.connect(DialogicUtil._on_export_vector_submitted.bind(property_changed))
		TYPE_STRING:
			if property_info['hint'] & PROPERTY_HINT_FILE or property_info['hint'] & PROPERTY_HINT_DIR:
				input = load("res://addons/dialogic/Editor/Events/Fields/field_file.tscn").instantiate()
				input.file_filter = property_info['hint_string']
				input.file_mode = FileDialog.FILE_MODE_OPEN_FILE
				if property_info['hint'] == PROPERTY_HINT_DIR:
					input.file_mode = FileDialog.FILE_MODE_OPEN_DIR
				input.property_name = property_info['name']
				input.placeholder = "Default"
				input.hide_reset = true
				if value != null:
					input.set_value(value)
				input.value_changed.connect(DialogicUtil._on_export_file_submitted.bind(property_changed))
			elif property_info['hint'] & PROPERTY_HINT_ENUM:
				input = OptionButton.new()
				var options: PackedStringArray = []
				for x in property_info['hint_string'].split(','):
					options.append(x.split(':')[0].strip_edges())
					input.add_item(options[-1])
				if value != null:
					input.select(options.find(value))
				input.item_selected.connect(DialogicUtil._on_export_string_enum_submitted.bind(property_info.name, options, property_changed))
			else:
				input = LineEdit.new()
				if value != null:
					input.text = value
				input.text_submitted.connect(DialogicUtil._on_export_input_text_submitted.bind(property_info.name, property_changed))
		TYPE_OBJECT:
			input = load("res://addons/dialogic/Editor/Common/hint_tooltip_icon.tscn").instantiate()
			input.hint_text = "Objects/Resources as settings are currently not supported. \nUse @export_file('*.extension') instead and load the resource once needed."
		_:
			input = LineEdit.new()
			if value != null:
				input.text = value
			input.text_submitted.connect(DialogicUtil._on_export_input_text_submitted.bind(property_info.name, property_changed))
	return input


static func _on_export_input_text_submitted(text:String, property_name:String, callable: Callable) -> void:
	callable.call(property_name, var_to_str(text))

static func _on_export_bool_submitted(value:bool, property_name:String, callable: Callable) -> void:
	callable.call(property_name, var_to_str(value))

static func _on_export_color_submitted(color:Color, property_name:String, callable: Callable) -> void:
	callable.call(property_name, var_to_str(color))

static func _on_export_int_enum_submitted(item:int, property_name:String, callable: Callable) -> void:
	callable.call(property_name, var_to_str(item))

static func _on_export_number_submitted(value:float, property_name:String, callable: Callable) -> void:
	callable.call(property_name, var_to_str(value))

static func _on_export_file_submitted(property_name:String, value:String, callable: Callable) -> void:
	callable.call(property_name, var_to_str(value))

static func _on_export_string_enum_submitted(value:int, property_name:String, list:PackedStringArray, callable: Callable):
	callable.call(property_name, var_to_str(list[value]))

static func _on_export_vector_submitted(property_name:String, value:Vector2, callable: Callable) -> void:
	callable.call(property_name, var_to_str(value))

#endregion


#region EVENT DEFAULTS
################################################################################

static func get_custom_event_defaults(event_name:String) -> Dictionary:
	if Engine.is_editor_hint():
		return ProjectSettings.get_setting('dialogic/event_default_overrides', {}).get(event_name, {})
	else:
		if !Engine.get_main_loop().has_meta('dialogic_event_defaults'):
			Engine.get_main_loop().set_meta('dialogic_event_defaults', ProjectSettings.get_setting('dialogic/event_default_overrides', {}))
		return Engine.get_main_loop().get_meta('dialogic_event_defaults').get(event_name, {})

#endregion


#region CONVERSION
################################################################################

static func str_to_bool(boolstring:String) -> bool:
	return true if boolstring == "true" else false


static func logical_convert(value:Variant) -> Variant:
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


## Takes [param source] and builds a dictionary of keys only.
## The values are `null`.
static func str_to_hash_set(source: String) -> Dictionary:
	var dictionary := Dictionary()

	for character in source:
		dictionary[character] = null

	return dictionary

#endregion
