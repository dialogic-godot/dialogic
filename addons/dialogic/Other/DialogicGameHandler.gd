extends Node

enum states {IDLE, SHOWING_TEXT, ANIMATING, AWAITING_CHOICE, WAITING}
enum ClearFlags {FullClear=0, KeepVariables=1, TimelineInfoOnly=2}

var current_timeline: Variant = null
var current_timeline_events: Array = []
var character_directory: Dictionary = {}
var timeline_directory: Dictionary = {}
var _event_script_cache: Array[DialogicEvent] = []

var current_state: Variant = null:
	get:
		return current_state
	set(new_state):
		current_state = new_state
		emit_signal('state_changed', new_state)

var paused := false:
	set(value):
		paused = value
		if paused:
			for subsystem in get_children():
				if subsystem.has_method('pause'):
					subsystem.pause()
			dialogic_paused.emit()
		else:
			for subsystem in get_children():
				if subsystem.has_method('resume'):
					subsystem.resume()
			dialogic_resumed.emit()

signal dialogic_paused
signal dialogic_resumed

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
	
	timeline_ended.connect(_on_timeline_ended)


################################################################################
## 						TIMELINE+EVENT HANDLING
################################################################################
# Method to start a timeline without adding a layout scene.
# @timeline can be either a loaded timeline resource or a path to a timeline file.
# @label_or_idx can be a label (string) or index (int) to skip to immediatly.
func start_timeline(timeline:Variant, label_or_idx:Variant = "") -> void:
	# load the resource if only the path is given
	if typeof(timeline) == TYPE_STRING:
		#check the lookup table if it's not a full file name
		if timeline.contains("res://"):
			timeline = load(timeline)
		else: 
			timeline = load(find_timeline(timeline))
		if timeline == null:
			printerr("[Dialogic] There was an error loading this timeline. Check the filename, and the timeline for errors")
			return
	await timeline.process()
	
	current_timeline = timeline
	current_timeline_events = current_timeline.events
	current_event_idx = -1
	
	if typeof(label_or_idx) == TYPE_STRING:
		if label_or_idx:
			if has_subsystem('Jump'):
				self.Jump.jump_to_label(label_or_idx)
	elif typeof(label_or_idx) == TYPE_INT:
		if label_or_idx >-1:
			current_event_idx = label_or_idx -1
	
	timeline_started.emit()
	handle_next_event()


# Preloader function, prepares a timeline and returns an object to hold for later
## TODO: Question: why is this taking a variant and then only allowing a string?
func preload_timeline(timeline_resource:Variant) -> Variant:
	# I think ideally this should be on a new thread, will test
	if typeof(timeline_resource) == TYPE_STRING:
		timeline_resource = load(timeline_resource)
		if timeline_resource == null:
			printerr("[Dialogic] There was an error preloading this timeline. Check the filename, and the timeline for errors")
			return false
		else:
			await timeline_resource.process()
			return timeline_resource
	return false


func end_timeline() -> void:
	current_timeline = null
	current_timeline_events = []
	clear(ClearFlags.TimelineInfoOnly)
	timeline_ended.emit()


func handle_next_event(ignore_argument:Variant = "") -> void:
	handle_event(current_event_idx+1)


func handle_event(event_index:int) -> void:
	if not current_timeline:
		return
	
	if paused:
		await dialogic_resumed
	
	if event_index >= len(current_timeline_events):
		if has_subsystem('Jump') and !self.Jump.is_jump_stack_empty():
			self.Jump.resume_from_last_jump()
			return
		else:
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
	event_handled.emit(current_timeline_events[event_index])


# resets dialogics state fully or partially
# by using the clear flags you can specify what info should be kept
# for example at timeline end usually it doesn't clear node or subsystem info
func clear(clear_flags:=ClearFlags.FullClear) -> bool:
	
	if !clear_flags & ClearFlags.TimelineInfoOnly:
		for subsystem in get_children():
			subsystem.clear_game_state(clear_flags)
	
	# Resetting variables
	current_timeline = null
	current_event_idx = -1
	current_timeline_events = []
	current_state = states.IDLE
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

	return current_state_info.duplicate(true)


func load_full_state(state_info:Dictionary) -> void:
	clear()
	current_state_info = state_info
	if current_state_info.get('current_timeline', null):
		start_timeline(current_state_info.current_timeline, current_state_info.get('current_event_idx', 0))

	for subsystem in get_children():
		subsystem.load_game_state()

################################################################################
##						SUB-SYTSEMS
################################################################################
func collect_subsystems() -> void:
	# This also builds the event script cache as well
	_event_script_cache = []
	
	for indexer in DialogicUtil.get_indexers():
		
		# build event cache
		for event in indexer._get_events():
			if not 'event_end_branch.gd' in event and not 'event_text.gd' in event:
				_event_script_cache.append(load(event).new())
		
		# build the subsystems (only at runtime)
		if !Engine.is_editor_hint():
			for subsystem in indexer._get_subsystems():
				add_subsytsem(subsystem.name, subsystem.script)
	
	# Events are checked in order while testing them. EndBranch needs to be first, Text needs to be last
	_event_script_cache.push_front(DialogicEndBranchEvent.new())
	_event_script_cache.push_back(DialogicTextEvent.new())
	Engine.get_main_loop().set_meta("dialogic_event_cache", _event_script_cache)
	

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

# #TODO initial work on a unified method for character and timeline directories!
#func build_directory(file_extension:String) -> Dictionary:
#	var files :Array[String] = DialogicUtil.list_resources_of_type(file_extension)
#
#	# First sort by length of path, so shorter paths are first	
#	files.sort_custom(func(a, b): return a.count("/") < b.count("/"))
#
#
#
#	return {}


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
	var depth := 1
	
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
	
	Engine.get_main_loop().set_meta("dialogic_character_directory", character_directory)


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
	var depth := 1
	

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
	Engine.get_main_loop().set_meta("dialogic_timeline_directory", timeline_directory)

func find_timeline(path: String) -> String:
	if path in timeline_directory.keys():
		return timeline_directory[path]
	else:
		for i in timeline_directory.keys():
			if timeline_directory[i].contains(path):
				return timeline_directory[i]
	
	return ""


################################################################################
##						FOR END USER
################################################################################
# Method to start a timeline AND ensure that a layout scene is present.
# For argument info, checkout start_timeline() and add_layout_node()
# -> returns the layout node 
func start(timeline:Variant, label:Variant="") -> Node:
	var scene := add_layout_node()
	Dialogic.start_timeline(timeline, label)
	return scene


# Makes sure the layout scene is instanced and will show it if it was hidden.
# The layout scene will always be added to the tree root. 
# If you need a layout inside your game, instance it manually and use start_timeline() instead of start().
func add_layout_node(scene_path := "", export_overrides := {}) -> Node:
	var scene :Node = null
	if is_instance_valid(get_tree().get_meta('dialogic_layout_node', null)):
		scene = get_tree().get_meta('dialogic_layout_node', null)
	
	# create a new one if none exists or a different one was requested
	if !is_instance_valid(scene) or (!scene_path.is_empty() and scene.get_meta('scene_path', scene_path) != scene_path):
		if is_instance_valid(scene):
			scene.queue_free()
		
		if scene_path.is_empty():
			scene_path = ProjectSettings.get_setting(
						'dialogic/layout/layout_scene', 
						DialogicUtil.get_default_layout())
		
		scene = load(scene_path).instantiate()
		scene.set_meta('scene_path', scene_path)
		
		get_parent().call_deferred("add_child", scene)
		get_tree().set_meta('dialogic_layout_node', scene)
	
	# otherwise use existing scene
	else:
		scene = get_tree().get_meta('dialogic_layout_node', null)
		scene.show()
	
	# apply custom export overrides everytime
	if export_overrides.is_empty():
		DialogicUtil.apply_scene_export_overrides(
			scene, 
			ProjectSettings.get_setting('dialogic/layout/export_overrides', {}))
	else:
		DialogicUtil.apply_scene_export_overrides(scene, export_overrides)
	
	return scene


func get_layout_node() -> Node:
	return get_tree().get_meta('dialogic_layout_node', null)


func _on_timeline_ended():
	if is_instance_valid(get_tree().get_meta('dialogic_layout_node', '')):
		match ProjectSettings.get_setting('dialogic/layout/end_behaviour', 0):
			0:
				get_tree().get_meta('dialogic_layout_node', '').queue_free()
			1:
				get_tree().get_meta('dialogic_layout_node', '').hide()


func has_active_layout_node() -> bool:
	if !is_instance_valid(get_tree().get_meta('dialogic_layout_node', null)) or !get_tree().get_meta('dialogic_layout_node').visible:
		return false
	return true
