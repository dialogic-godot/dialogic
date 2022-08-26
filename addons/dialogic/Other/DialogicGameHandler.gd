extends Node

enum states {IDLE, SHOWING_TEXT, ANIMATING, AWAITING_CHOICE, WAITING}

var current_timeline: Variant = null
var current_timeline_events: Array = []
var character_directory: Dictionary = {}

var current_state: Variant = null:
	get:
		return current_state
	set(new_state):
		current_state = new_state
		emit_signal('state_changed', new_state)
var paused := false
var current_event_idx: int = 0
var current_state_info: Dictionary = {}

# Thread and variables for handling delayed loader
var deferred_loader: Thread
var deferred_loader_semaphore: Semaphore = Semaphore.new()
var deferred_loader_safe_to_run: bool = false
var deferred_loader_running: bool = false
var deferred_loader_cleanup: bool = false

signal state_changed(new_state)
signal timeline_ended()
signal timeline_started()
signal event_handled(resource)

signal signal_event(argument)
signal text_signal(argument)

func _ready() -> void:
	#thread is only used at runtime for deferred loading
	#as it's not particularly modifying much, just finishing a step we're deferring to fill in the event data, it should be safe for use without semaphores or mutexes
	if Engine.is_editor_hint() == false:
		deferred_loader = Thread.new()
		
		# Runtime will also build the character_directory dictionary. Editor will have to handle it a different way
		var characters: Array = DialogicUtil.list_resources_of_type(".dch")
		
		for character in characters:
			var charfile: DialogicCharacter= load(character)
			character_directory[character] = charfile
		
	collect_subsystems()
	clear()
	
# 
func _exit_tree():
	# Thread needs to be disposed of
	if Engine.is_editor_hint() == false:
		deferred_loader_cleanup = true
		deferred_loader_safe_to_run = false
		deferred_loader_semaphore.post()
		deferred_loader.wait_to_finish()
	# Probably other cleanup here


################################################################################
## 						TIMELINE+EVENT HANDLING
################################################################################
func start_timeline(timeline_resource:Variant, label_or_idx:Variant = "") -> void:
	# Cancel all remaining tasks in the preloader thread
	#If loader is running, wait for it to stop current line
	deferred_loader_safe_to_run = false
	while deferred_loader_running:		
		continue
		
	# load the resource if only the path is given
	if typeof(timeline_resource) == TYPE_STRING:
		timeline_resource = load(timeline_resource)
		if timeline_resource == null:
			assert(false, "There was an error loading this timeline. Check the filename, and the timeline for errors")
	
	current_timeline = timeline_resource
	current_timeline_events = current_timeline.get_events()
	current_event_idx = -1
	
	if typeof(label_or_idx) == TYPE_STRING:
		if label_or_idx:
			jump_to_label(label_or_idx)
	elif typeof(label_or_idx) == TYPE_INT:
		if label_or_idx >-1:
			current_event_idx = label_or_idx -1
	
	# begin the runtime thread for processing events
	if deferred_loader.is_alive() == false:
		var threadFunction = Callable(self, "_thread_deferred_timeline_items")
		deferred_loader.start(threadFunction)
		deferred_loader_safe_to_run = true
		deferred_loader_semaphore.post()
	else:
		deferred_loader_safe_to_run = true
		deferred_loader_semaphore.post()

	
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
		current_timeline_events[event_index]._load_from_string(current_timeline_events[event_index]['deferred_processing_text'])
	
	current_event_idx = event_index
	
	#print("\n[D] Handle Event ", event_index, ": ", event)
	if current_timeline_events[event_index].continue_at_end:
		#print("    -> WILL AUTO CONTINUE!")
		current_timeline_events[event_index].event_finished.connect(handle_next_event, CONNECT_ONESHOT)
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
	print(state_info)
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
	for script in DialogicUtil.get_event_scripts():
		var x = load(script).new()
		for i in x.get_required_subsystems():
			if i.has('subsystem') and not has_subsystem(i.name):
				add_subsytsem(i.name, i.subsystem)


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
##						PROCESSING THREADS
################################################################################
func _thread_deferred_timeline_items() -> void:
	while(true):
		deferred_loader_semaphore.wait()
		#break out needed when closing app so thread can end
		if deferred_loader_cleanup: 
			break
		deferred_loader_running = true

		for event in current_timeline_events:
			# continue processing as long as it's safe, aborts when a new start_timeline() is run as that will replace the timeline
			if deferred_loader_safe_to_run:
				# Load everything else now
				# This will load all the timelines this timeline jumps into as well
				if event['event_node_ready'] == false:
					event._load_from_string(event['deferred_processing_text'])
					
				if event['event_name'] == "Jump":
					event.load_timeline()
					

		#while we still have free time on the thread, we can also start to process any timelines we loaded here, for events other than jumps:
		for event in current_timeline_events:
			if deferred_loader_safe_to_run:
				if event['event_name'] == "Jump":
					if event['Timeline']['_events']:
						for timeline_event in event['Timeline']['_events']:
							if deferred_loader_safe_to_run:

								if timeline_event['event_node_ready'] == false && timeline_event['event_name'] != "Jump":
									timeline_event._load_from_string(timeline_event['deferred_processing_text'])
					
		deferred_loader_running = false


func _thread_deferred_preload_timeline() -> void:
	pass
