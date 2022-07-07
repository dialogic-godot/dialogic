extends DialogicSubsystem

####################################################################################################
##					STATE
####################################################################################################

func clear_game_state():
	# loading default variables
	dialogic.current_state_info['variables'] = DialogicUtil.get_project_setting('dialogic/variables', {})

func load_game_state():
	pass

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
	
	var variables = dialogic.current_state_info['variables']
	
	if '{' in text: # Otherwise, why bother?
		# Trying to extract the curly brackets from the text
		var regex = RegEx.new()
		regex.compile("\\{(?<variable>[^{}]*)\\}")
		var to_replace = []
		for result in regex.search_all(text):
			to_replace.append(result.get_string('variable'))
		
		# Getting all the autoloads
		var autoloads = get_autoloads()
		
		# Trying to replace the values
		var parsed = text
		for entry in to_replace:
			if '.' in entry:
				var query = entry.split('.')
				var from = query[0]
				var variable = query[1]
				
				# first look for autoloads
				for a in autoloads:
					if a.name == from:
						parsed = parsed.replace('{' + entry + '}', a.get(variable))
						continue
				
				# if none is found, try getting it from the dialogic variables
				var cur_dat = variables
				for i in query:
					if i.strip_edges() in cur_dat.keys():
						if typeof(cur_dat[i.strip_edges()]) == TYPE_DICTIONARY:
							cur_dat = cur_dat[i.strip_edges()]
						else:
							parsed = parsed.replace('{' + entry + '}', cur_dat[i.strip_edges()])
			
			# see if it's a built-in variable
			if entry.strip_edges() in variables:
				if typeof(variables[entry.strip_edges()]) == TYPE_STRING:
					parsed = parsed.replace('{' + entry + '}', variables[entry.strip_edges()])
		return parsed
	return text


func set_variable(variable_name: String, value: String) -> bool:
	
	
	# Getting all the autoloads
	var autoloads = get_autoloads()
	
	if '.' in variable_name:
		var query = variable_name.split('.')
		var from = query[0]
		var variable = query[1]
		for a in autoloads:
			if a.name == from:
				a.set(variable, value)
				return true
		
		# if none is found, try getting it from the dialogic variables
		_set_value_in_dictionary(variable_name, dialogic.current_state_info['variables'], value) 
	
	if variable_name in dialogic.current_state_info['variables'].keys():
		if typeof(dialogic.current_state_info['variables'][variable_name]) == TYPE_STRING:
			dialogic.current_state_info['variables'][variable_name] = value
			return true
	return false

# this will set a value in a dictionary (or a sub-dictionary based on the path)
# e.g. it could set "Something.Something.Something" in {'Something':{'Something':{'Someting':"value"}}}
func _set_value_in_dictionary(path:String, dictionary:Dictionary, value):
	if '.' in path:
		var from = path.split('.')[0]
		if from in dictionary.keys():
			dictionary[from] = _set_value_in_dictionary(path.trim_prefix(from+"."), dictionary[from], value)
	else:
		if path in dictionary.keys():
			dictionary[path] = value
	return dictionary


func get_autoloads() -> Array:
	var autoloads = []
	for c in get_tree().root.get_children():
		autoloads.append(c)
	return autoloads


# allows to set dialogic built-in variables 
func _set(property, value):
	var variables = dialogic.current_state_info['variables']
	if property in variables.keys():
		if typeof(variables[property]) != TYPE_DICTIONARY:
			variables[property] = value
			return true
		if value is VariableFolder:
			return true 

# allows to get dialogic built-in variables 
func _get(property):
	if property in dialogic.current_state_info['variables'].keys():
		if typeof(dialogic.current_state_info['variables'][property]) == TYPE_DICTIONARY:
			return VariableFolder.new(dialogic.current_state_info['variables'][property], property, self)
		else:
			return dialogic.current_state_info['variables'][property]


class VariableFolder:
	var data = {}
	var path = ""
	var outside
	func _init(_data, _path, _outside):
		data = _data
		path = _path
		outside = _outside
	
	func _get(property):
		if property in data:
			if typeof(data[property]) == TYPE_DICTIONARY:
				return VariableFolder.new(data[property], path+"."+property, outside)
			else:
				return data[property]
	
	func _set(property, value):
		if not value is VariableFolder:
			outside._set_value_in_dictionary(path+"."+property, outside.dialogic.current_state_info['variables'], value)
			return true
		elif VariableFolder:
			return true
