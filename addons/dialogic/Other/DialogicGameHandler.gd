extends Node

enum states {IDLE, SHOWING_TEXT, ANIMATING, AWAITING_CHOICE, WAITING}

var current_timeline = null
var current_timeline_events = []


var current_state = null setget set_current_state
var current_event_idx = 0

var current_state_info :Dictionary = {}


signal state_changed(new_state)
signal timeline_ended()
signal signal_event(argument)
signal text_signal(argument)

func _ready() -> void:
	collect_subsystems()
	clear()


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
## 						STATE
################################################################################
func set_current_state(new_state:int) -> void:
	#print('~~~ CHANGE STATE ', ["IDLE", "TEXT", "ANIM", "CHOICE", "WAIT",][new_state])
	current_state = new_state
	emit_signal('state_changed', new_state)


func execute_condition(condition:String) -> bool:
	var expr = Expression.new()
	var autoload_names = []
	var autoloads = []
	for c in get_tree().root.get_children():
		autoloads.append(c)
		autoload_names.append(c.name)
	expr.parse(condition, autoload_names)
	return true if expr.execute(autoloads) else false


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

func _get(property):
	if has_subsystem(property):
		return get_node(property)

func _set(property, value):
	if has_subsystem(property):
		return true
