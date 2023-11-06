extends DialogicSubsystem

## Subsystem that manages variables and allows to access them.

## Emitted if a dialogic variable changes
signal variable_changed(info:Dictionary)
## Emitted on any set variable event
signal variable_was_set(info:Dictionary)


####################################################################################################
##					STATE
####################################################################################################

func clear_game_state(clear_flag:=Dialogic.ClearFlags.FULL_CLEAR):
	# loading default variables
	if ! clear_flag & Dialogic.ClearFlags.KEEP_VARIABLES:
		reset()


func load_game_state(load_flag:=LoadFlags.FULL_LOAD):
	if load_flag == LoadFlags.ONLY_DNODES:
		return
	dialogic.current_state_info['variables'] = merge_folder(dialogic.current_state_info['variables'], ProjectSettings.get_setting('dialogic/variables', {}).duplicate(true))


func merge_folder(new, defs) -> Dictionary:
	# also go through all groups in this folder
	for x in new.keys():
		if x in defs and typeof(new[x]) == TYPE_DICTIONARY:
			new[x] = merge_folder(new[x], defs[x])
	# add all new variables
	for x in defs.keys():
		if not x in new:
			new[x] = defs[x]
	return new

####################################################################################################
##					MAIN METHODS
####################################################################################################
## This function will try to get the value of variables provided inside curly brackets
## and replace them with their values.
## It will:
## - look for the strings to replace
## - search all tree nodes (autoloads)
## - try to get the value from context
##
## So if you provide a string like `Hello, how are you doing {Game.player_name}
## it will try to search for an autoload with the name `Game` and get the value
## of `player_name` to replace it.
func parse_variables(text:String) -> String:
	# First some dirty checks to avoid parsing
	if not '{' in text:
		return text

	# Trying to extract the curly brackets from the text
	var regex := RegEx.new()
	regex.compile("(?<!\\\\)\\{(?<variable>([^{}]|\\{.*\\})*)\\}")

	var parsed := text.replace('\\{', '{')
	for result in regex.search_all(text):
		var value := get_variable(result.get_string('variable'), "<NOT FOUND>")
		parsed = parsed.replace("{"+result.get_string('variable')+"}", str(value))

	return parsed


func set_variable(variable_name: String, value: Variant) -> bool:
	variable_name = variable_name.trim_prefix('{').trim_suffix('}')

	# First assume this is a simple dialogic variable
	if has(variable_name):
		_set_value_in_dictionary(variable_name, dialogic.current_state_info['variables'], value)
		variable_changed.emit({'variable':variable_name, 'new_value':value})
		return true

	# Second assume this is an autoload variable
	elif '.' in variable_name:
		var from := variable_name.get_slice('.', 0)
		var variable := variable_name.trim_prefix(from+'.')

		for a in get_autoloads():
			if a.name == from:
				a.set(variable, value)
				return true

	printerr("[Dialogic] Tried setting non-existant variable '"+variable_name+"'.")
	return false


func get_variable(variable_path:String, default :Variant= null) -> Variant:
	if variable_path.begins_with('{') and variable_path.ends_with('}') and variable_path.count('{') == 1:
		variable_path = variable_path.trim_prefix('{').trim_suffix('}')

	# First assume this is just a single variable
	var value := _get_value_in_dictionary(variable_path, dialogic.current_state_info['variables'])
	if value != null:
		return value

	# Second assume this is an expression.
	else:
		value = dialogic.Expression.execute_string(variable_path, null)
		if value != null:
			return value


	# If everything fails, tell the user and return the default
	printerr("[Dialogic] Failed parsing variable/expression '"+variable_path+"'.")
	return default


## Resets all variables or a specific variable to the value(s) defined in the variable editor
func reset(variable:='') -> void:
	if variable.is_empty():
		dialogic.current_state_info['variables'] = ProjectSettings.get_setting('dialogic/variables', {}).duplicate(true)
	else:
		_set_value_in_dictionary(variable, dialogic.current_state_info['variables'], _get_value_in_dictionary(variable, ProjectSettings.get_setting('dialogic/variables', {})))


## Returns true if a variable with the given path exists
func has(variable:='') -> bool:
	return _get_value_in_dictionary(variable, dialogic.current_state_info['variables']) != null


## This will set a value in a dictionary (or a sub-dictionary based on the path)
## e.g. it could set "Something.Something.Something" in {'Something':{'Something':{'Someting':"value"}}}
func _set_value_in_dictionary(path:String, dictionary:Dictionary, value):
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
func _get_value_in_dictionary(path:String, dictionary:Dictionary, default= null) -> Variant:
	if '.' in path:
		var from := path.split('.')[0]
		if from in dictionary.keys():
			return _get_value_in_dictionary(path.trim_prefix(from+"."), dictionary[from], default)
	else:
		if path in dictionary.keys():
			return dictionary[path]
	return default

func get_autoloads() -> Array:
	var autoloads := []
	for c in get_tree().root.get_children():
		autoloads.append(c)
	return autoloads


## Allows to set dialogic built-in variables
func _set(property, value) -> bool:
	property = str(property)
	var variables: Dictionary = dialogic.current_state_info['variables']
	if property in variables.keys():
		if typeof(variables[property]) != TYPE_DICTIONARY:
			variables[property] = value
			return true
		if value is VariableFolder:
			return true
	return false


## Allows to get dialogic built-in variables
func _get(property):
	property = str(property)
	if property in dialogic.current_state_info['variables'].keys():
		if typeof(dialogic.current_state_info['variables'][property]) == TYPE_DICTIONARY:
			return VariableFolder.new(dialogic.current_state_info['variables'][property], property, self)
		else:
			return DialogicUtil.logical_convert(dialogic.current_state_info['variables'][property])


func folders() -> Array:
	var result := []
	for i in dialogic.current_state_info['variables'].keys():
		if dialogic.current_state_info['variables'][i] is Dictionary:
			result.append(VariableFolder.new(dialogic.current_state_info['variables'][i], i, self))
	return result


func variables(absolute:=false) -> Array:
	var result := []
	for i in dialogic.current_state_info['variables'].keys():
		if not dialogic.current_state_info['variables'][i] is Dictionary:
			result.append(i)
	return result

class VariableFolder:
	var data := {}
	var path := ""
	var outside
	func _init(_data, _path, _outside):
		data = _data
		path = _path
		outside = _outside

	func _get(property):
		property = str(property)
		if property in data:
			if typeof(data[property]) == TYPE_DICTIONARY:
				return VariableFolder.new(data[property], path+"."+property, outside)
			else:
				return DialogicUtil.logical_convert(data[property])

	func _set(property, value) -> bool:
		property = str(property)
		if not value is VariableFolder:
			outside._set_value_in_dictionary(path+"."+property, outside.dialogic.current_state_info['variables'], value)
		return true

	func has(key) -> bool:
		return key in data

	func folders() -> Array:
		var result := []
		for i in data.keys():
			if data[i] is Dictionary:
				result.append(VariableFolder.new(data[i], path+"."+i, outside))
		return result

	func variables(absolute:=false) -> Array:
		var result := []
		for i in data.keys():
			if not data[i] is Dictionary:
				if absolute:
					result.append(path+'.'+i)
				else:
					result.append(i)
		return result
