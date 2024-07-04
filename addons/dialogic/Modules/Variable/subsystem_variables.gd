extends DialogicSubsystem

## Subsystem that manages variables and allows to access them.

## Emitted if a dialogic variable changes, gives a dictionary with the following keys:[br]
## [br]
## Key         |   Value Type  | Value [br]
## ----------- | ------------- | ----- [br]
## `variable`  | [type String] | The name of the variable that is getting changed. [br]
## `new_value` | [type Variant]| The value that [variable] has after the change (the result). [br]
signal variable_changed(info:Dictionary)

## Emitted on a set variable event, gives a dictionary with the following keys:[br]
## [br]
## Key         |   Value Type  | Value [br]
## ----------- | ------------- | ----- [br]
## `variable`  | [type String] | The name of the variable that is getting changed. [br]
## `orig_value`| [type Variant]| The value that [variable] had before. [br]
## `new_value` | [type Variant]| The value that [variable] has after the change (the result). [br]
## `value`     | [type Variant]| The value that the variable is changed by/to. [br]
## `value_str` | [type String] | Whatever has been given as the value (not interpreted, so a variable is just a string).[br]
signal variable_was_set(info:Dictionary)


#region STATE
####################################################################################################

func clear_game_state(clear_flag:=DialogicGameHandler.ClearFlags.FULL_CLEAR):
	# loading default variables
	if ! clear_flag & DialogicGameHandler.ClearFlags.KEEP_VARIABLES:
		reset()


func load_game_state(load_flag:=LoadFlags.FULL_LOAD):
	if load_flag == LoadFlags.ONLY_DNODES:
		return
	dialogic.current_state_info['variables'] = merge_folder(dialogic.current_state_info['variables'], ProjectSettings.get_setting('dialogic/variables', {}).duplicate(true))

#endregion


#region MAIN METHODS
####################################################################################################

## This function will try to get the value of variables provided inside curly brackets
## and replace them with their values.
## It will:
## - look for the strings to replace
## - search all autoloads
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
		var value: Variant = get_variable(result.get_string('variable'), "<NOT FOUND>")
		parsed = parsed.replace("{"+result.get_string('variable')+"}", str(value))

	return parsed


func set_variable(variable_name: String, value: Variant) -> bool:
	variable_name = variable_name.trim_prefix('{').trim_suffix('}')

	# First assume this is a simple dialogic variable
	if has(variable_name):
		DialogicUtil._set_value_in_dictionary(variable_name, dialogic.current_state_info['variables'], value)
		variable_changed.emit({'variable':variable_name, 'new_value':value})
		return true

	# Second assume this is an autoload variable
	elif '.' in variable_name:
		var from := variable_name.get_slice('.', 0)
		var variable := variable_name.trim_prefix(from+'.')

		var autoloads := get_autoloads()
		var object: Object = null
		if from in autoloads:
			object = autoloads[from]
			while variable.count("."):
				from = variable.get_slice('.', 0)
				if from in object and object.get(from) is Object:
					object = object.get(from)
				variable = variable.trim_prefix(from+'.')

		if object:
			var sub_idx := ""
			if '[' in variable:
				sub_idx = variable.substr(variable.find('['))
			variable = variable.trim_suffix(sub_idx)
			sub_idx = sub_idx.trim_prefix('[').trim_suffix(']')

			if variable in object:
				match typeof(object.get(variable)):
					TYPE_ARRAY:
						if not sub_idx:
							if typeof(value) == TYPE_ARRAY:
								object.set(variable, value)
								return true
						elif sub_idx.is_valid_float():
							object.get(variable).remove_at(int(sub_idx))
							object.get(variable).insert(int(sub_idx), value)
							return true
					TYPE_DICTIONARY:
						if not sub_idx:
							if typeof(value) == TYPE_DICTIONARY:
								object.set(variable, value)
								return true
						else:
							object.get(variable).merge({str_to_var(sub_idx):value}, true)
							return true
					_:
						object.set(variable, value)
						return true

	printerr("[Dialogic] Tried setting non-existant variable '"+variable_name+"'.")
	return false


func get_variable(variable_path:String, default: Variant = null, no_warning := false) -> Variant:
	if variable_path.begins_with('{') and variable_path.ends_with('}') and variable_path.count('{') == 1:
		variable_path = variable_path.trim_prefix('{').trim_suffix('}')

	# First assume this is just a single variable
	var value: Variant = DialogicUtil._get_value_in_dictionary(variable_path, dialogic.current_state_info['variables'])
	if value != null:
		return value

	# Second assume this is an expression.
	else:
		value = dialogic.Expressions.execute_string(variable_path, null, no_warning)
		if value != null:
			return value

	# If everything fails, tell the user and return the default
	if not no_warning:
		printerr("[Dialogic] Failed parsing variable/expression '"+variable_path+"'.")
	return default


## Resets all variables or a specific variable to the value(s) defined in the variable editor
func reset(variable:="") -> void:
	if variable.is_empty():
		dialogic.current_state_info['variables'] = ProjectSettings.get_setting("dialogic/variables", {}).duplicate(true)
	else:
		DialogicUtil._set_value_in_dictionary(variable, dialogic.current_state_info['variables'], DialogicUtil._get_value_in_dictionary(variable, ProjectSettings.get_setting('dialogic/variables', {})))


## Returns true if a variable with the given path exists
func has(variable:="") -> bool:
	return DialogicUtil._get_value_in_dictionary(variable, dialogic.current_state_info['variables']) != null



## Allows to set dialogic built-in variables
func _set(property, value) -> bool:
	property = str(property)
	var vars: Dictionary = dialogic.current_state_info['variables']
	if property in vars.keys():
		if typeof(vars[property]) != TYPE_DICTIONARY:
			vars[property] = value
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


func variables(_absolute:=false) -> Array:
	var result := []
	for i in dialogic.current_state_info['variables'].keys():
		if not dialogic.current_state_info['variables'][i] is Dictionary:
			result.append(i)
	return result
#endregion

#region HELPERS
################################################################################

func get_autoloads() -> Dictionary:
	var autoloads := {}
	for node: Node in get_tree().root.get_children():
		autoloads[node.name] = node
	return autoloads


func merge_folder(new:Dictionary, defs:Dictionary) -> Dictionary:
	# also go through all groups in this folder
	for x in new.keys():
		if x in defs and typeof(new[x]) == TYPE_DICTIONARY:
			new[x] = merge_folder(new[x], defs[x])
	# add all new variables
	for x in defs.keys():
		if not x in new:
			new[x] = defs[x]
	return new

#endregion

#region VARIABLE FOLDER
################################################################################
class VariableFolder:
	var data := {}
	var path := ""
	var outside: DialogicSubsystem

	func _init(_data:Dictionary, _path:String, _outside:DialogicSubsystem):
		data = _data
		path = _path
		outside = _outside


	func _get(property:StringName):
		property = str(property)
		if property in data:
			if typeof(data[property]) == TYPE_DICTIONARY:
				return VariableFolder.new(data[property], path+"."+property, outside)
			else:
				return DialogicUtil.logical_convert(data[property])


	func _set(property:StringName, value:Variant) -> bool:
		property = str(property)
		if not value is VariableFolder:
			DialogicUtil._set_value_in_dictionary(path+"."+property, outside.dialogic.current_state_info['variables'], value)
		return true


	func has(key:String) -> bool:
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

#endregion
