extends Node

enum states {IDLE, SHOWING_TEXT, ANIMATING, AWAITING_CHOICE, WAITING}

var current_timeline = null
var current_timeline_events = []


var current_state = null setget set_current_state
var current_event_idx = 0

var current_state_info :Dictionary = {}

var variables # These are the built-in dialogic variables

signal state_changed(new_state)
signal timeline_ended()
signal signal_event(argument)
signal text_signal(argument)

func _ready() -> void:
	collect_subsystems()
	clear()
	variables = DialogicUtil.get_project_setting('dialogic/variables', {})

################################################################################
## 						INPUT (WIP)
################################################################################
# This shouldn't be handled by this script I think, but for testing purposes this works.
func _input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if current_state == states.IDLE:
			handle_next_event()
		elif current_state == states.SHOWING_TEXT:
			self.Text.skip_text_animation()


################################################################################
## 						TIMELINE+EVENT HANDLING
################################################################################
func start_timeline(timeline_resource, label_or_idx = "") -> void:
	# load the resource if only the path is given
	if typeof(timeline_resource) == TYPE_STRING:
		timeline_resource = load(timeline_resource)
	
	
	current_timeline = timeline_resource
	current_timeline_events = current_timeline.get_events()
	current_event_idx = -1
	
	if typeof(label_or_idx) == TYPE_STRING:
		if label_or_idx:
			jump_to_label(label_or_idx)
	elif typeof(label_or_idx) == TYPE_INT:
		if label_or_idx >-1:
			current_event_idx = label_or_idx -1
	
	handle_next_event()


func end_timeline():
	current_timeline = null
	current_timeline_events = []
	emit_signal("timeline_ended")


func handle_next_event(ignore_argument = "") -> void:
	handle_event(current_event_idx+1)


func handle_event(event_index:int) -> void:
	if not current_timeline:
		return
	
	if event_index >= len(current_timeline_events):
		emit_signal('timeline_ended')
		return
	
	current_event_idx = event_index
	var event:DialogicEvent = current_timeline_events[event_index]
	#print("\n[D] Handle Event ", event_index, ": ", event)
	if event.continue_at_end:
		#print("    -> WILL AUTO CONTINUE!")
		event.connect("event_finished", self, 'handle_next_event', [], CONNECT_ONESHOT)
	event.execute(self)


func jump_to_label(label:String) -> void:
	var idx = -1
	while true:
		idx += 1
		var event = current_timeline.get_event(idx)
		if not event:
			idx = current_event_idx
			break
		if event is DialogicLabelEvent and event.Name == label:
			break
	current_event_idx = idx


func clear():
	for subsystem in Dialogic.get_children():
		subsystem.clear_game_state()
	current_timeline = null
	current_event_idx = -1
	current_timeline_events = []
	current_state = states.IDLE
	return true


################################################################################
## 						VARIABLES/CONDITIONS
################################################################################
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
		_set_value_in_dictionary(variable_name, variables, value) 
	
	if variable_name in variables:
		if typeof(variables[variable_name]) == TYPE_STRING:
			variables[variable_name] = value
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

func set_current_state(new_state:int) -> void:
	#print('~~~ CHANGE STATE ', ["IDLE", "TEXT", "ANIM", "CHOICE", "WAIT",][new_state])
	current_state = new_state
	emit_signal('state_changed', new_state)


func execute_condition(condition:String) -> bool:
	var expr = Expression.new()
	expr.parse(condition)
	return true if expr.execute() else false


func get_autoloads() -> Array:
	var autoloads = []
	for c in get_tree().root.get_children():
		autoloads.append(c)
	return autoloads


# allows to set dialogic built-in variables 
func _set(property, value):
	if property in variables.keys():
		if typeof(variables[property]) != TYPE_DICTIONARY:
			variables[property] = value
			return true
		if value is VariableFolder:
			return true 

# allows to get dialogic built-in variables 
func _get(property):
	if has_subsystem(property):
		return get_node(property)
	if property in variables.keys():
		if property in variables:
			if typeof(variables[property]) == TYPE_DICTIONARY:
				return VariableFolder.new(variables[property], property, self)
			else:
				return variables[property]


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
			outside._set_value_in_dictionary(path+"."+property, outside.variables, value)
			return true
		elif VariableFolder:
			return true

################################################################################
## 						SAVING & LOADING
################################################################################
func get_full_state() -> Dictionary:
	if current_timeline:
		current_state_info['current_event_idx'] = current_event_idx
		current_state_info['current_timeline'] = current_timeline.resource_path
	else:
		current_state_info['current_event_idx'] = -1
		current_state_info['current_timeline'] = null

	return current_state_info


func load_full_state(state_info:Dictionary) -> void:
	current_state_info = state_info
	print(state_info)
	if current_state_info.get('current_timeline', null):
		start_timeline(current_state_info.current_timeline, str(current_state_info.get('current_event_idx', 0)))
	for subsystem in get_children():
		subsystem.load_game_state()

################################################################################
##						SUB-SYTSEMS
################################################################################
func collect_subsystems():
	for script in DialogicUtil.get_event_scripts():
		var x = load(script).new()
		for i in x.get_required_subsystems():
			if not has_subsystem(i[0]):
				add_subsytsem(i[0], i[1])

func has_subsystem(_name):
	return has_node(_name)

func get_subsystem(_name):
	return get_node(_name)

func add_subsytsem(_name, _script_path):
	var node = Node.new()
	node.name = _name
	node.set_script(load(_script_path))
	node.dialogic = self
	add_child(node)
	return node
