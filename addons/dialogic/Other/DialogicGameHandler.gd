extends Node

enum states {IDLE, SHOWING_TEXT, ANIMATING, AWAITING_CHOICE, WAITING}

var current_timeline: Variant = null
var current_timeline_events: Array = []
var character_directory: Dictionary = {}
var timeline_directory: Dictionary = {}
var _event_script_cache: Array = []

var current_state: Variant = null:
	get:
		return current_state
	set(new_state):
		current_state = new_state
		emit_signal('state_changed', new_state)
var paused := false
var current_event_idx: int = 0
var current_state_info: Dictionary = {}

signal state_changed(new_state)
signal timeline_ended()
signal timeline_started()
signal event_handled(resource)

signal signal_event(argument)
signal text_signal(argument)


func _ready() -> void:
	rebuild_character_directory()
	rebuild_timeline_directory()
	
	collect_subsystems()

	clear()



################################################################################
## 						TIMELINE+EVENT HANDLING
################################################################################
func start_timeline(timeline_resource:Variant, label_or_idx:Variant = "") -> void:

		
	# load the resource if only the path is given
	if typeof(timeline_resource) == TYPE_STRING:
		#check the lookup table if it's not a full file name
		if timeline_resource.contains("res://"):
			timeline_resource = load(timeline_resource)
		else: 
			timeline_resource = load(find_timeline(timeline_resource))
		if timeline_resource == null:
			assert(false, "There was an error loading this timeline. Check the filename, and the timeline for errors")
	
	timeline_resource = process_timeline(timeline_resource)
		
	current_timeline = timeline_resource
	current_timeline_events = current_timeline.get_events()
	current_event_idx = -1
	
	if typeof(label_or_idx) == TYPE_STRING:
		if label_or_idx:
			jump_to_label(label_or_idx)
	elif typeof(label_or_idx) == TYPE_INT:
		if label_or_idx >-1:
			current_event_idx = label_or_idx -1
	

	
	emit_signal('timeline_started')
	handle_next_event()


# Preloader function, prepares a timeline and returns an object to hold for later
func preload_timeline(timeline_resource:Variant) -> Variant:
	#I think ideally this should be on a new thread, will test
	if typeof(timeline_resource) == TYPE_STRING:
		timeline_resource = load(timeline_resource)
		if timeline_resource == null:
			assert(false, "There was an error loading this timeline. Check the filename, and the timeline for errors")
		else:
			timeline_resource = process_timeline(timeline_resource)
			return timeline_resource
	return false


func end_timeline() -> void:
	current_timeline = null
	current_timeline_events = []
	clear()
	emit_signal("timeline_ended")


func handle_next_event(ignore_argument:Variant = "") -> void:
	handle_event(current_event_idx+1)


func handle_event(event_index:int) -> void:
	if not current_timeline:
		return
	
	if event_index >= len(current_timeline_events):
		end_timeline()
		return
	
	#actually process the event now, since we didnt earlier at runtime
	#this needs to happen before we create the copy DialogicEvent variable, so it doesn't throw an error if not ready
	if current_timeline_events[event_index]['event_node_ready'] == false:
		current_timeline_events[event_index]._load_from_string(current_timeline_events[event_index]['event_node_as_text'])
	
	current_event_idx = event_index
	
	#print("\n[D] Handle Event ", event_index, ": ", event)
	if current_timeline_events[event_index].continue_at_end:
		#print("    -> WILL AUTO CONTINUE!")
		if not current_timeline_events[event_index].event_finished.is_connected(handle_next_event):
			current_timeline_events[event_index].event_finished.connect(handle_next_event, CONNECT_ONE_SHOT)
	current_timeline_events[event_index].execute(self)
	emit_signal('event_handled', current_timeline_events[event_index])


func jump_to_label(label:String) -> void:
	var idx: int = -1
	while true:
		idx += 1
		var event: Variant = current_timeline.get_event(idx)
		if not event:
			idx = current_event_idx
			break
		if event is DialogicLabelEvent and event.Name == label:
			break
	current_event_idx = idx


func clear() -> bool:
	for subsystem in get_children():
		subsystem.clear_game_state()
		
	# Clearing existing Dialogic main nodes
	for i in get_tree().get_nodes_in_group('dialogic_main_node'):
				i.queue_free()
	
	# Resetting variables
	current_timeline = null
	current_event_idx = -1
	current_timeline_events = []
	current_state = states.IDLE
	return true


func pause() -> void:
	if paused: 
		return
	paused = true
	for subsystem in get_children():
		if subsystem.has_method('pause'):
			subsystem.pause()


func resume() -> void:
	if !paused: 
		return
	paused = false
	for subsystem in get_children():
		if subsystem.has_method('resume'):
			subsystem.resume()

################################################################################
## 						STATE
################################################################################

func execute_condition(condition:String) -> bool:
	var regex: RegEx = RegEx.new()
	regex.compile('{(\\w.*)}')
	var result := regex.search_all(condition)
	if result:
		for res in result:
			var r_string: String = res.get_string()
			var replacement: String = "VAR." + r_string.substr(1,r_string.length()-2)
			condition = condition.replace(r_string, replacement)
	
	var expr: Expression = Expression.new()
	var autoload_names: Array = []
	var autoloads: Array = []
	for c in get_tree().root.get_children():
		autoloads.append(c)
		autoload_names.append(c.name)
	expr.parse(condition, autoload_names)
	if expr.execute(autoloads, self):
		return true
	return false


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
	if has_subsystem('Portraits'):
		current_state_info['current_portrait_positions'] = self.Portraits.current_positions
		current_state_info['default_portrait_positions'] = self.Portraits._default_positions
	
	return current_state_info


func load_full_state(state_info:Dictionary) -> void:
	for subsystem in get_children():
		subsystem.clear_game_state()
	current_state_info = state_info
	if current_state_info.get('current_timeline', null):
		start_timeline(current_state_info.current_timeline, current_state_info.get('current_event_idx', 0))
	if has_subsystem('Portraits'):
		if current_state_info.get('current_portrait_positions', null):
			self.Portraits.current_positions = current_state_info['current_portrait_positions']
			self.Portraits._default_positions = current_state_info['default_portrait_positions']
	for subsystem in get_children():
		subsystem.load_game_state()

################################################################################
##						SUB-SYTSEMS
################################################################################
func collect_subsystems() -> void:
	# This also builds th event script cache as well
	for script in DialogicUtil.get_event_scripts():
		var x = load(script).new()
		
		x.set_meta("script_path", script)
		if script != "res://addons/dialogic/Events/End Branch/event.gd":
			_event_script_cache.push_back(x)
		
		#only build the subsystems at runtime
		if !Engine.is_editor_hint():
			for i in x.get_required_subsystems():
				if i.has('subsystem') and not has_subsystem(i.name):
					add_subsytsem(i.name, i.subsystem)
					
		# Events are checked in order while testing them. EndBranch needs to be first, Text needs to be last
	var x = load("res://addons/dialogic/Events/End Branch/event.gd").new()
	x.set_meta("script_path", "res://addons/dialogic/Events/End Branch/event.gd")
	_event_script_cache.push_front(x)

				
	for i in _event_script_cache.size():
		if _event_script_cache[i].get_meta("script_path") == "res://addons/dialogic/Events/Text/event.gd":
			_event_script_cache.push_back(_event_script_cache[i])
			_event_script_cache.remove_at(i)
			break


func has_subsystem(_name:String) -> bool:
	return has_node(_name)


func get_subsystem(_name:String) -> Variant:
	return get_node(_name)


func add_subsytsem(_name:String, _script_path:String) -> Node:
	var node:Node = Node.new()
	node.name = _name
	node.set_script(load(_script_path))
	node.dialogic = self
	add_child(node)
	return node


func _get(property):
	if has_subsystem(property):
		return get_node(str(property))


func _set(property, value):
	if has_subsystem(property):
		return true


################################################################################
##						PROCESSING FUNCTIONS
################################################################################

func rebuild_character_directory() -> void:
	var characters: Array = DialogicUtil.list_resources_of_type(".dch")
	
	# First sort by length of path, so shorter paths are first
	characters.sort_custom(func(a, b):return a.count("/") < b.count("/"))
	
	# next we prepare the additional arrays needed for building the depth tree
	var shortened_paths:Array = []
	var reverse_array:Array = []
	var reverse_array_splits:Array = []
	
	for i in characters.size():
		characters[i] = characters[i].replace("res:///", "res://")
		var path = characters[i].replace("res://","").replace(".dch", "")
		if path[0] == "/":
			path = path.right(-1)
		shortened_paths.append(path) 
		
		#split the shortened path up, and reverse it
		var path_breakdown = path.split("/")
		path_breakdown.reverse()
		
		#Add the name of the file at beginning now, and another array saving the reversed split within each element
		reverse_array.append(path_breakdown[0])
		reverse_array_splits.append(path_breakdown)
		
	
	# Now the three arrays are prepped, begin the depth search
	var clean_search_path:bool = false
	var depth = 1
	
	while !clean_search_path:
		var interim_array:Array = []
		clean_search_path = true
		
		for i in shortened_paths.size():
			if reverse_array.count(reverse_array[i]) > 1:
				clean_search_path = false
				if depth < reverse_array_splits[i].size():
					interim_array.append(reverse_array_splits[i][depth] + "/" + reverse_array[i])
				else:
					interim_array.append(reverse_array[i])
			else:
				interim_array.append(reverse_array[i])
		depth += 1
		reverse_array = interim_array		
			
	# Now finally build the database from those arrays
	for i in characters.size():
		var entry:Dictionary = {}
		var charfile: DialogicCharacter= load(characters[i])
		entry['resource'] = charfile
		entry['full_path'] = characters[i]
		entry['unique_short_path'] = reverse_array[i]
		character_directory[reverse_array[i]] = entry


func rebuild_timeline_directory() -> void:
	var characters: Array = DialogicUtil.list_resources_of_type(".dtl")
	
	# First sort by length of path, so shorter paths are first
	characters.sort_custom(func(a, b):return a.count("/") < b.count("/"))
	
	# next we prepare the additional arrays needed for building the depth tree
	var shortened_paths:Array = []
	var reverse_array:Array = []
	var reverse_array_splits:Array = []
	
	for i in characters.size():
		characters[i] = characters[i].replace("res:///", "res://")
		var path = characters[i].replace("res://","").replace(".dtl", "")
		if path[0] == "/":
			path = path.right(-1)
		shortened_paths.append(path) 
		
		#split the shortened path up, and reverse it
		var path_breakdown = path.split("/")
		path_breakdown.reverse()
		
		#Add the name of the file at beginning now, and another array saving the reversed split within each element
		reverse_array.append(path_breakdown[0])
		reverse_array_splits.append(path_breakdown)
		
	
	# Now the three arrays are prepped, begin the depth search
	var clean_search_path:bool = false
	var depth = 1
	

	while !clean_search_path:
		var interim_array:Array = []
		clean_search_path = true
		
		for i in shortened_paths.size():
			if reverse_array.count(reverse_array[i]) > 1:
				clean_search_path = false
				if depth < reverse_array_splits[i].size():
					interim_array.append(reverse_array_splits[i][depth] + "/" + reverse_array[i])
				else:
					interim_array.append(reverse_array[i])
			else:
				interim_array.append(reverse_array[i])
		depth += 1
		reverse_array = interim_array		
			
			

	
	# Now finally build the database from those arrays
	for i in characters.size():
		timeline_directory[reverse_array[i]] = characters[i]


func find_timeline(path: String) -> String:
	if path in timeline_directory.keys():
		return timeline_directory[path]
	else:
		for i in timeline_directory.keys():
			if timeline_directory[i].contains(path):
				return timeline_directory[i]
				
	return ""


func process_timeline(timeline: DialogicTimeline) -> DialogicTimeline:
	if timeline != null:
		if timeline.events_processed:
			return timeline
		else:
			#print(str(Time.get_ticks_msec()) + ": Starting process unloaded timeline")	
			var end_event: DialogicEndBranchEvent 
			for i in _event_script_cache:
				if i.get_meta("script_path") == "res://addons/dialogic/Events/End Branch/event.gd":
						end_event = i.duplicate()
						break
			
			var prev_indent := ""
			var events := []
			
			# this is needed to add a end branch event even to empty conditions/choices
			var prev_was_opener := false
			
			var lines := timeline.events
			var idx := -1
			
			while idx < len(lines)-1:
				idx += 1
				var line: String = ""
				if typeof(lines[idx]) == TYPE_STRING:
					line = lines[idx]
				else:
					line = lines[idx]['event_node_as_text']
				
				
				var line_stripped :String = line.strip_edges(true, false)
				if line_stripped.is_empty():
					continue
				var indent :String= line.substr(0,len(line)-len(line_stripped))
				
				if len(indent) < len(prev_indent):
					for i in range(len(prev_indent)-len(indent)):
						events.append(end_event.duplicate())
				
				elif prev_was_opener and len(indent) == len(prev_indent):
					events.append(end_event.duplicate())
				prev_indent = indent
				var event_content :String = line_stripped

				var event :Variant
				for i in _event_script_cache:
					if i._test_event_string(event_content):
						event = i.duplicate()
						break
				
				# add the following lines until the event says it's full there is an empty line or the indent changes
				while !event.is_string_full_event(event_content):
					idx += 1
					if idx == len(lines):
						break
					var following_line :String = lines[idx]
					var following_line_stripped :String = following_line.strip_edges(true, false)
					var following_line_indent :String = following_line.substr(0,len(following_line)-len(following_line_stripped))
					if following_line_stripped.is_empty():
						break
					if following_line_indent != indent:
						idx -= 1
						break
					event_content += "\n"+following_line_stripped
				
				if Engine.is_editor_hint():
					# Unlike at runtime, for some reason here the event scripts can't access the scene tree to get to the character directory, so we will need to pass it to it before processing
					if event['event_name'] == 'Character' || event['event_name'] == 'Text':
						event.set_meta('editor_character_directory', character_directory)


				event._load_from_string(event_content)
				event['event_node_as_text'] = event_content

				events.append(event)
				prev_was_opener = event.can_contain_events
				
			

			if !prev_indent.is_empty():
				for i in range(len(prev_indent)):
					events.append(end_event.duplicate())
			
			timeline.events = events	
			timeline.events_processed = true
			#print(str(Time.get_ticks_msec()) + ": Finished process unloaded timeline")	
			return timeline
	else:
		return DialogicTimeline.new()


################################################################################
##						FOR END USER
################################################################################
func start(timeline, single_instance = true):
	var dialog_scene_path: String = DialogicUtil.get_project_setting(
		'dialogic/editor/default_dialog_scene', "res://addons/dialogic/Example Assets/example-scenes/DialogicDefaultScene.tscn")
	if single_instance:
		if get_tree().get_nodes_in_group('dialogic_main_node').is_empty():
			var scene = load(dialog_scene_path).instantiate()
			get_parent().call_deferred("add_child", scene)
	Dialogic.start_timeline(timeline)

func is_running() -> bool:
	if get_tree().get_nodes_in_group('dialogic_main_node').is_empty():
		return false
	return true
