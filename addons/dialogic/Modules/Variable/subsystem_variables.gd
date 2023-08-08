extends DialogicSubsystem

## Subsystem that manages variables and allows to access them.

# Emitted if a dialogic variable changes
signal variable_changed(info:Dictionary)
# Emitted on any set variable event
signal variable_was_set(info:Dictionary)


####################################################################################################
##					STATE
####################################################################################################

func clear_game_state(clear_flag:=Dialogic.ClearFlags.FULL_CLEAR):
	# loading default variables
	if ! clear_flag & Dialogic.ClearFlags.KEEP_VARIABLES:
		reset()


func load_game_state():
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

func parse_variables(text:String) -> String:
	# This function will try to get the value of variables provided inside curly brackets
	# and replace them with their values.
	# It will:
	# - look for the strings to replace
	# - search all tree nodes (autoloads)
	# - try to get the value from context
	#
	# So if you provide a string like `Hello, how are you doing {Game.player_name}
	# it will try to search for an autoload with the name `Game` and get the value
	# of `player_name` to replace it.
	
	if '{' in text: # Otherwise, why bother?
		# Trying to extract the curly brackets from the text
		var regex := RegEx.new()
		regex.compile("(?<!\\\\)\\{(?<variable>([^{}]|\\{.*\\})*)\\}")
		var parsed := text.replace('\\{', '{')
		for result in regex.search_all(text):
			var value := get_variable(result.get_string('variable'), "<NOT FOUND>")
			parsed = parsed.replace("{"+result.get_string('variable')+"}", str(value))
		return parsed
	return text


func set_variable(variable_name: String, value: Variant) -> bool:
	variable_name = variable_name.trim_prefix('{').trim_suffix('}')
	
	# Getting all the autoloads
	var autoloads := get_autoloads()
	
	if '.' in variable_name:
		var query := variable_name.split('.')
		var from := query[0]
		var variable := query[1]
		for a in autoloads:
			if a.name == from:
				a.set(variable, value)
				return true
		
		# if none is found, try getting it from the dialogic variables
		_set_value_in_dictionary(variable_name, dialogic.current_state_info['variables'], value) 
		variable_changed.emit({'variable':variable_name, 'new_value':value})
	
	elif variable_name in dialogic.current_state_info['variables'].keys():
		dialogic.current_state_info['variables'][variable_name] = value
		variable_changed.emit({'variable':variable_name, 'new_value':value})
		return true
	else:
		printerr("Dialogic: Tried accessing non-existant variable '"+variable_name+"'.")
	return false


func get_variable(variable_path:String, default :Variant= null) -> Variant:
	variable_path = variable_path.trim_prefix('{').trim_suffix('}')
	
	# Getting all the autoloads
	var autoloads := get_autoloads()
	
	if variable_path in dialogic.current_state_info['variables'].keys():
		return dialogic.current_state_info['variables'][variable_path]
	
	else:
		var value :=  _get_value_in_dictionary(variable_path, dialogic.current_state_info['variables']) 
		if value != null:
			return value
	
		value = dialogic.Expression.execute_string(variable_path, null)
		if value != null:
			return value
		
	printerr("Dialogic: Failed accessing '"+variable_path+"'.")
	return default


# resets all variables or a specific variable to the value(s) defined in the variable editor
func reset(variable:='') -> void:
	if variable.is_empty():
		dialogic.current_state_info['variables'] = ProjectSettings.get_setting('dialogic/variables', {}).duplicate(true)
	else:
		_set_value_in_dictionary(variable, dialogic.current_state_info['variables'], _get_value_in_dictionary(variable, ProjectSettings.get_setting('dialogic/variables', {})))


# returns true if a variable with the given path exists
func has(variable:='') -> bool:
	return _get_value_in_dictionary(variable, dialogic.current_state_info['variables']) != null


# this will set a value in a dictionary (or a sub-dictionary based on the path)
# e.g. it could set "Something.Something.Something" in {'Something':{'Something':{'Someting':"value"}}}
func _set_value_in_dictionary(path:String, dictionary:Dictionary, value):
	if '.' in path:
		var from := path.split('.')[0]
		if from in dictionary.keys():
			dictionary[from] = _set_value_in_dictionary(path.trim_prefix(from+"."), dictionary[from], value)
	else:
		if path in dictionary.keys():
			dictionary[path] = value
	return dictionary


# this will get a value in a dictionary (or a sub-dictionary based on the path)
# e.g. it could get "Something.Something.Something" in {'Something':{'Something':{'Someting':"value"}}}
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


# allows to set dialogic built-in variables 
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


# allows to get dialogic built-in variables 
func _get(property):
	property = str(property)
	if property in dialogic.current_state_info['variables'].keys():
		if typeof(dialogic.current_state_info['variables'][property]) == TYPE_DICTIONARY:
			return VariableFolder.new(dialogic.current_state_info['variables'][property], property, self)
		else:
			return DialogicUtil.logical_convert(dialogic.current_state_info['variables'][property])


class VariableFolder:
	var data = {}
	var path = ""
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
	
	func _set(property, value):
		property = str(property)
		if not value is VariableFolder:
			outside._set_value_in_dictionary(path+"."+property, outside.dialogic.current_state_info['variables'], value)
			return true
		elif VariableFolder:
			return true
