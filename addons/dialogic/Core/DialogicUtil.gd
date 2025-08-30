@tool
class_name DialogicUtil

## Script that container helper methods for both editor and game execution.
## Used whenever the same thing is needed in different parts of the plugin.

#region EDITOR

## This method should be used instead of EditorInterface.get_editor_scale(), because if you use that
## it will run perfectly fine from the editor, but crash when the game is exported.
static func get_editor_scale() -> float:
	if Engine.is_editor_hint():
		return get_dialogic_plugin().get_editor_interface().get_editor_scale()
	return 1.0


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
static func listdir(path: String, files_only:= true, _throw_error:= true, full_file_path:= false, include_imports := false) -> Array:
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


## This is a private and editor-only function.
##
## Populates the [class DialogicGameHandler] with new custom subsystems by
## directly manipulating the file's content and then importing the file.
static func _update_autoload_subsystem_access() -> void:
	if not Engine.is_editor_hint():
		printerr("[Dialogic] This function is only available in the editor.")
		return

	var script: Script = load("res://addons/dialogic/Core/DialogicGameHandler.gd")
	var new_subsystem_access_list := "#region SUBSYSTEMS\n"
	var subsystems_sorted := []

	for indexer: DialogicIndexer in get_indexers(true, true):

		for subsystem: Dictionary in indexer._get_subsystems().duplicate(true):
			subsystems_sorted.append(subsystem)

	subsystems_sorted.sort_custom(func (a: Dictionary, b: Dictionary) -> bool:
		return a.name < b.name
	)

	for subsystem: Dictionary in subsystems_sorted:
		new_subsystem_access_list += '\nvar {name} := preload("{script}").new():\n\tget: return get_subsystem("{name}")\n'.format(subsystem)

	new_subsystem_access_list += "\n#endregion"
	script.source_code = RegEx.create_from_string(r"#region SUBSYSTEMS\n#*\n((?!#endregion)(.*\n))*#endregion").sub(script.source_code, new_subsystem_access_list)
	ResourceSaver.save(script)
	Engine.get_singleton("EditorInterface").get_resource_filesystem().reimport_files(["res://addons/dialogic/Core/DialogicGameHandler.gd"])


static func get_indexers(include_custom := true, force_reload := false) -> Array[DialogicIndexer]:
	if Engine.get_main_loop().has_meta('dialogic_indexers') and not force_reload:
		return Engine.get_main_loop().get_meta('dialogic_indexers')

	var indexers: Array[DialogicIndexer] = []
	for file in listdir(DialogicUtil.get_module_path(''), false):
		var possible_script: String = DialogicUtil.get_module_path(file).path_join("index.gd")
		if ResourceLoader.exists(possible_script):
			indexers.append(load(possible_script).new())

	if include_custom:
		var extensions_folder: String = ProjectSettings.get_setting('dialogic/extensions_folder', "res://addons/dialogic_additions/")
		for file in listdir(extensions_folder, false, false):
			var possible_script: String = extensions_folder.path_join(file + "/index.gd")
			if ResourceLoader.exists(possible_script):
				indexers.append(load(possible_script).new())

	Engine.get_main_loop().set_meta('dialogic_indexers', indexers)
	return indexers



## Turns a [param file_path] from `some_file.png` to `Some File`.
static func pretty_name(file_path: String) -> String:
	var _name := file_path.get_file().trim_suffix("." + file_path.get_extension())
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


#region MULTITWEEN
################################################################################
static func multitween(tweened_value:Variant, item:Node, property:String, part:String) -> void:
	var parts: Dictionary = item.get_meta(property+'_parts', {})
	parts[part] = tweened_value

	if not item.has_meta(property+'_base_value') and not 'base' in parts:
		item.set_meta(property+'_base_value', item.get(property))

	var final_value: Variant = parts.get('base', item.get_meta(property+'_base_value', item.get(property)))

	for key in parts:
		if key == 'base':
			continue
		else:
			final_value += parts[key]

	item.set(property, final_value)
	item.set_meta(property+'_parts', parts)

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


static func get_variable_value_type(value:Variant) -> VarTypes:
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
	var property_info: Array[Dictionary] = node.script.get_script_property_list()
	for i in property_info:
		if i['usage'] & PROPERTY_USAGE_EDITOR:
			defaults[i['name']] = node.get(i['name'])
	Engine.get_main_loop().get_meta('dialogic_scene_export_defaults')[node.script.resource_path] = defaults
	return defaults

#endregion

#region MAKE CUSTOM

static func make_file_custom(original_file:String, target_folder:String, new_file_name := "", new_folder_name := "") -> String:
	if not ResourceLoader.exists(original_file):
		push_error("[Dialogic] Unable to make file with invalid path custom!")
		return ""

	if new_folder_name:
		target_folder = target_folder.path_join(new_folder_name)
		DirAccess.make_dir_absolute(target_folder)

	if new_file_name.is_empty():
		new_file_name = "custom_" + original_file.get_file()

	if not new_file_name.ends_with(original_file.get_extension()):
		new_file_name += "." + original_file.get_extension()

	var target_file := target_folder.path_join(new_file_name)

	customize_file(original_file, target_file)

	get_dialogic_plugin().get_editor_interface().get_resource_filesystem().scan_sources()

	return target_file


static func customize_file(original_file:String, target_file:String) -> String:
	#print("\nCUSTOMIZE FILE")
	#printt(original_file, "->", target_file)

	DirAccess.copy_absolute(original_file, target_file)

	var file := FileAccess.open(target_file, FileAccess.READ)
	var file_text := file.get_as_text()
	file.close()

	# If we are customizing a scene, we check for any resources used in that scene that are in the same folder.
	# Those will be copied as well and the scene will be modified to point to them.
	if file_text.begins_with('[gd_'):
		var base_path: String = original_file.get_base_dir()

		var remove_uuid_regex := r'\[gd_.* (?<uid>uid="uid:[^"]*")'
		var result := RegEx.create_from_string(remove_uuid_regex).search(file_text)
		if result:
			file_text = file_text.replace(result.get_string("uid"), "")

		# This regex also removes the UID referencing the original resource
		var file_regex := r'(uid="[^"]*" )?\Qpath="'+base_path+r'\E(?<file>[^"]*)"'
		result = RegEx.create_from_string(file_regex).search(file_text)
		while result:
			var found_file_name := result.get_string('file')
			var found_file_path := base_path.path_join(found_file_name)
			var target_file_path := target_file.get_base_dir().path_join(found_file_name)

			# Files found in this file will ALSO be customized.
			customize_file(found_file_path, target_file_path)

			file_text = file_text.replace(found_file_path, target_file_path)

			result = RegEx.create_from_string(file_regex).search(file_text)

	file = FileAccess.open(target_file, FileAccess.WRITE)
	file.store_string(file_text)
	file.close()

	return target_file

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
			input.custom_minimum_size.x = get_editor_scale() * 50
		TYPE_INT:
			if property_info['hint'] & PROPERTY_HINT_ENUM:
				input = OptionButton.new()
				for x in property_info['hint_string'].split(','):
					input.add_item(x.split(':')[0])
				if value != null:
					input.select(value)
				input.item_selected.connect(DialogicUtil._on_export_int_enum_submitted.bind(property_info.name, property_changed))
			else:
				input = load("res://addons/dialogic/Editor/Events/Fields/field_number.tscn").instantiate()
				input.property_name = property_info['name']
				input.use_int_mode()

				if ',' in property_info.hint_string:
					input.min_value = int(property_info.hint_string.get_slice(',', 0))
					input.max_value = int(property_info.hint_string.get_slice(',', 1))
					if property_info.hint_string.count(',') > 1:
						input.step = int(property_info.hint_string.get_slice(',', 2))
				else:
					input.step = 1
					input.max_value = INF
					input.min_value = -INF

				if value != null:
					input.set_value(value)
				input.value_changed.connect(DialogicUtil._on_export_number_submitted.bind(property_changed))
		TYPE_FLOAT:
			input = load("res://addons/dialogic/Editor/Events/Fields/field_number.tscn").instantiate()
			input.property_name = property_info['name']
			input.use_float_mode()
			input.step = 0.01
			if ',' in property_info.hint_string:
				input.min_value = float(property_info.hint_string.get_slice(',', 0))
				input.max_value = float(property_info.hint_string.get_slice(',', 1))
				if property_info.hint_string.count(',') > 1:
					input.step = float(property_info.hint_string.get_slice(',', 2))
			if value != null:
				input.set_value(value)
			input.value_changed.connect(DialogicUtil._on_export_number_submitted.bind(property_changed))
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4:
			var vectorSize: String = type_string(typeof(value))[-1]
			input = load("res://addons/dialogic/Editor/Events/Fields/field_vector" + vectorSize + ".tscn").instantiate()
			input.property_name = property_info['name']
			input.set_value(value)
			input.value_changed.connect(DialogicUtil._on_export_vector_submitted.bind(property_changed))
		TYPE_VECTOR2I, TYPE_VECTOR3I, TYPE_VECTOR4I:
			var vectorSize: String = type_string(typeof(value))[-2]
			input = load("res://addons/dialogic/Editor/Events/Fields/field_vector" + vectorSize + ".tscn").instantiate()
			input.step = 1
			input.property_name = property_info['name']
			input.set_value(value)
			input.value_changed.connect(DialogicUtil._on_export_vectori_submitted.bind(property_changed))
		TYPE_STRING:
			if property_info['hint'] & PROPERTY_HINT_FILE or property_info['hint'] & PROPERTY_HINT_DIR:
				input = load("res://addons/dialogic/Editor/Events/Fields/field_file.tscn").instantiate()
				input.show_editing_button = true
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
		TYPE_DICTIONARY:
			input = load("res://addons/dialogic/Editor/Events/Fields/field_dictionary.tscn").instantiate()
			input.property_name = property_info["name"]
			input.set_value(value)
			input.value_changed.connect(_on_export_dict_submitted.bind(property_changed))
		TYPE_OBJECT:
			input = load("res://addons/dialogic/Editor/Common/hint_tooltip_icon.tscn").instantiate()
			input.hint_text = "Objects/Resources as settings are currently not supported. \nUse @export_file('*.extension') instead and load the resource once needed."

		_:
			input = LineEdit.new()
			if value != null:
				input.text = value
			input.text_submitted.connect(_on_export_input_text_submitted.bind(property_info.name, property_changed))
	return input


static func _on_export_input_text_submitted(text:String, property_name:String, callable: Callable) -> void:
	callable.call(property_name, var_to_str(text))

static func _on_export_bool_submitted(value:bool, property_name:String, callable: Callable) -> void:
	callable.call(property_name, var_to_str(value))

static func _on_export_color_submitted(color:Color, property_name:String, callable: Callable) -> void:
	callable.call(property_name, var_to_str(color))

static func _on_export_int_enum_submitted(item:int, property_name:String, callable: Callable) -> void:
	callable.call(property_name, var_to_str(item))

static func _on_export_number_submitted(property_name:String, value:float, callable: Callable) -> void:
	callable.call(property_name, var_to_str(value))

static func _on_export_file_submitted(property_name:String, value:String, callable: Callable) -> void:
	callable.call(property_name, var_to_str(value))

static func _on_export_string_enum_submitted(value:int, property_name:String, list:PackedStringArray, callable: Callable):
	callable.call(property_name, var_to_str(list[value]))

static func _on_export_vector_submitted(property_name:String, value:Variant, callable: Callable) -> void:
	callable.call(property_name, var_to_str(value))

static func _on_export_vectori_submitted(property_name:String, value:Variant, callable: Callable) -> void:
	match typeof(value):
		TYPE_VECTOR2: value = Vector2i(value)
		TYPE_VECTOR3: value = Vector3i(value)
		TYPE_VECTOR4: value = Vector4i(value)
	callable.call(property_name, var_to_str(value))

static func _on_export_dict_submitted(property_name:String, value:Variant, callable: Callable) -> void:
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


static func get_character_suggestions(_search_text:String, current_value:DialogicCharacter = null, allow_none := true, allow_all:= false, editor_node:Node = null) -> Dictionary:
	var suggestions := {}

	var icon := load("res://addons/dialogic/Editor/Images/Resources/character.svg")

	if allow_none and current_value:
		suggestions['(No one)'] = {'value':'', 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}

	if allow_all:
		suggestions['ALL'] = {'value':'--All--', 'tooltip':'All currently joined characters leave', 'editor_icon':["GuiEllipsis", "EditorIcons"]}

	# Get characters in the current timeline and place them at the top of suggestions.
	if editor_node:
		var recent_characters := []
		var timeline_node := editor_node.get_parent().find_parent("Timeline") as DialogicEditor
		for event_node in timeline_node.find_child("Timeline").get_children():
			if event_node == editor_node:
				break
			if event_node.resource is DialogicCharacterEvent or event_node.resource is DialogicTextEvent:
				recent_characters.append(event_node.resource.character)

		recent_characters.reverse()
		for character in recent_characters:
			if character and not character.get_character_name() in suggestions:
				suggestions[character.get_character_name()] = {'value': character.get_character_name(), 'tooltip': character.resource_path, 'icon': icon.duplicate()}

	var character_directory := DialogicResourceUtil.get_character_directory()
	for resource in character_directory.keys():
		suggestions[resource] = {'value': resource, 'tooltip': character_directory[resource], 'icon': icon}

	return suggestions


static func get_portrait_suggestions(search_text:String, character:DialogicCharacter, allow_empty := false, empty_text := "Don't Change") -> Dictionary:
	var icon := load("res://addons/dialogic/Editor/Images/Resources/portrait.svg")
	var suggestions := {}

	if allow_empty:
		suggestions[empty_text] = {'value':'', 'editor_icon':["GuiRadioUnchecked", "EditorIcons"]}

	if "{" in search_text:
		suggestions[search_text] = {'value':search_text, 'editor_icon':["Variant", "EditorIcons"]}

	if character != null:
		for portrait in character.portraits:
			suggestions[portrait] = {'value':portrait, 'icon':icon}

	return suggestions


static func get_portrait_position_suggestions(search_text := "") -> Dictionary:
	var icon := load(DialogicUtil.get_module_path("Character").path_join('portrait_position.svg'))

	var setting: String = ProjectSettings.get_setting('dialogic/portraits/position_suggestion_names', 'leftmost, left, center, right, rightmost')

	var suggestions := {}

	if not search_text.is_empty():
		suggestions[search_text] = {'value':search_text.strip_edges(), 'editor_icon':["GuiScrollArrowRight", "EditorIcons"]}

	for position_id in setting.split(','):
		suggestions[position_id.strip_edges()] = {'value':position_id.strip_edges(), 'icon':icon}
		if not search_text.is_empty() and position_id.strip_edges().begins_with(search_text):
			suggestions.erase(search_text)

	return suggestions


static func get_autoload_suggestions(filter:String="") -> Dictionary:
	var suggestions := {}

	for prop in ProjectSettings.get_property_list():
		if prop.name.begins_with('autoload/'):
			var some_autoload: String = prop.name.trim_prefix('autoload/')
			suggestions[some_autoload] = {'value': some_autoload, 'tooltip':some_autoload, 'editor_icon': ["Node", "EditorIcons"]}
			if filter.begins_with(some_autoload):
				suggestions[filter] = {'value': filter, 'editor_icon':["GuiScrollArrowRight", "EditorIcons"]}
	return suggestions


static func get_autoload_script_resource(autoload_name:String) -> Script:
	var script: Script
	if autoload_name and ProjectSettings.has_setting('autoload/'+autoload_name):
		var loaded_autoload := load(ProjectSettings.get_setting('autoload/'+autoload_name).trim_prefix('*'))

		if loaded_autoload is PackedScene:
			var packed_scene: PackedScene = loaded_autoload
			script = packed_scene.instantiate().get_script()

		else:
			script = loaded_autoload
	return script


static func get_autoload_method_suggestions(filter:String, autoload_name:String) -> Dictionary:
	var suggestions := {}

	var script := get_autoload_script_resource(autoload_name)
	if script:
		for script_method in script.get_script_method_list():
			if script_method.name.begins_with('@') or script_method.name.begins_with('_'):
				continue
			suggestions[script_method.name] = {'value': script_method.name, 'tooltip':script_method.name, 'editor_icon': ["Callable", "EditorIcons"]}

	if not filter.is_empty():
		suggestions[filter] = {'value': filter, 'editor_icon':["GuiScrollArrowRight", "EditorIcons"]}

	return suggestions


static func get_autoload_property_suggestions(_filter:String, autoload_name:String) -> Dictionary:
	var suggestions := {}
	var script := get_autoload_script_resource(autoload_name)
	if script:
		for property in script.get_script_property_list():
			if property.name.ends_with('.gd') or property.name.begins_with('_'):
				continue
			suggestions[property.name] = {'value': property.name, 'tooltip':property.name, 'editor_icon': ["MemberProperty", "EditorIcons"]}

	return suggestions


static func get_audio_bus_suggestions(_filter:= "") -> Dictionary:
	var bus_name_list := {}
	for i in range(AudioServer.bus_count):
		if i == 0:
			bus_name_list[AudioServer.get_bus_name(i)] = {'value':''}
		else:
			bus_name_list[AudioServer.get_bus_name(i)] = {'value':AudioServer.get_bus_name(i)}
	return bus_name_list


static func get_audio_channel_suggestions(_search_text:String) -> Dictionary:
	var suggestions := {}
	var channel_defaults := DialogicUtil.get_audio_channel_defaults()
	var cached_names := DialogicResourceUtil.get_channel_list()

	for i in channel_defaults.keys():
		if not cached_names.has(i):
			cached_names.append(i)

	cached_names.sort()

	for i in cached_names:
		if i.is_empty():
			continue

		suggestions[i] = {'value': i}

		if i in channel_defaults.keys():
			suggestions[i]["editor_icon"] = ["ProjectList", "EditorIcons"]
			suggestions[i]["tooltip"] = "A default channel defined in the settings."

		else:
			suggestions[i]["editor_icon"] = ["AudioStreamPlayer", "EditorIcons"]
			suggestions[i]["tooltip"] = "A temporary channel without defaults."

	return suggestions


static func get_audio_channel_defaults() -> Dictionary:
	return ProjectSettings.get_setting('dialogic/audio/channel_defaults', {
		"": {
			'volume': 0.0,
			'audio_bus': '',
			'fade_length': 0.0,
			'loop': false,
		},
		"music": {
			'volume': 0.0,
			'audio_bus': '',
			'fade_length': 0.0,
			'loop': true,
		}})


static func validate_audio_channel_name(text: String) -> Dictionary:
	var result := {}
	var channel_name_regex := RegEx.create_from_string(r'(?<dash_only>^-$)|(?<invalid>[^\w-]{1})')
	var matches := channel_name_regex.search_all(text)
	var invalid_chars := []

	for regex_match in matches:
		if regex_match.get_string('dash_only'):
			result['error_tooltip'] = "Channel name cannot be '-'."
			result['valid_text'] = ''
		else:
			var invalid_char = regex_match.get_string('invalid')
			if not invalid_char in invalid_chars:
				invalid_chars.append(invalid_char)

	if invalid_chars:
		result['valid_text'] = channel_name_regex.sub(text, '', true)
		result['error_tooltip'] = "Channel names cannot contain the following characters: " + "".join(invalid_chars)

	return result
