extends Node

## Autoload script that allows interacting with all of Dialogics systems:
## - Holds all important information about the current state of Dialogic.
## - Gives access to all the subystems.
## - Has methods to start timelines.


## States indicating different phases of dialog.
enum States {
	IDLE, 				## Dialogic is awaiting input to advance.
	REVEALING_TEXT, 	## Dialogic is currently revealing text.
	ANIMATING, 			## Some animation is happening.
	AWAITING_CHOICE, 	## Dialogic awaits the selection of a choice
	WAITING 			## Dialogic is currently awaiting something.
	}

## Flags indicating what to clear when calling Dialogic.clear()
enum ClearFlags {
	FULL_CLEAR = 0, 		## Clears all subsystems
	KEEP_VARIABLES = 1, 	## Clears all subsystems and info except for variables
	TIMLEINE_INFO_ONLY = 2	## Doesn't clear subsystems but current timeline and index
	}

## Reference to the timeline that is currently being executed
var current_timeline: DialogicTimeline = null
## List of the current timelines events
var current_timeline_events: Array = []

## Index of the event the timeline handeling is currently at.
var current_event_idx: int = 0
## Contains all information that subsystems consider
##  relevant for the current situation
var current_state_info: Dictionary = {}
## Current state (see [States] enum)
var current_state := States.IDLE:
	get:
		return current_state
	set(new_state):
		current_state = new_state
		emit_signal('state_changed', new_state)
## Emitted when [current_state] change.
signal state_changed(new_state)

## When true, many dialogic process won't continue until it's false again.
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

## Emitted when [paused] changes to true.
signal dialogic_paused
## Emitted when [paused] changes to false.
signal dialogic_resumed


signal timeline_ended()
signal timeline_started()
signal event_handled(resource)

## Emitted when the Signal event was reached
signal signal_event(argument)
## Emitted when [signal] effect was reached in text.
signal text_signal(argument)

## Directory that maps unique character names to each character resource
var character_directory: Dictionary = {}
## Directory that maps unique timeline names to each timeline resource.
var timeline_directory: Dictionary = {}
## Array holding a reference to each event once.
var _event_script_cache: Array[DialogicEvent] = []


## Autoloads are added first, so this happens REALLY early on game startup.
func _ready() -> void:
	rebuild_character_directory()
	rebuild_timeline_directory()

	collect_subsystems()

	clear()

	timeline_ended.connect(_on_timeline_ended)


#region TIMELINE & EVENT HANDLING
################################################################################

## Method to start a timeline AND ensure that a layout scene is present.
## For argument info, checkout start_timeline()
## -> returns the layout node
func start(timeline:Variant, label:Variant="") -> Node:
	var scene :Node= null
	if !has_active_layout_node():
		if has_subsystem('Styles'):
			scene = get_subsystem("Styles").add_layout_style()
		else:
			scene = add_layout_node()
	else:
		scene = get_layout_node()
	if not scene.is_node_ready():
		scene.ready.connect(clear.bind(ClearFlags.KEEP_VARIABLES))
		scene.ready.connect(start_timeline.bind(timeline, label))
	else:
		clear(ClearFlags.KEEP_VARIABLES)
		start_timeline(timeline, label)
	return scene


## Method that adds a layout scene unless the same scene is already in use.
## The layout scene will be added to the tree root and returned.
##
## To load a specific style you should instead call
##  Dialogic.Styles.add_layout_style(style_name)
## which uses this method internally but also applies style settings.
func add_layout_node(scene_path := "") -> Node:
	var scene: Node = get_layout_node()

	if (
		is_instance_valid(scene)
		and (
			scene_path.is_empty()
			or scene.get_meta('scene_path', scene_path) == scene_path
		)
	):
		# We have an existing valid scene matching the requested path, so
		# show it.
		scene.show()
	else:
		if is_instance_valid(scene):
			scene.queue_free()
		scene = null

		if scene_path.is_empty():
			scene_path = ProjectSettings.get_setting(
						'dialogic/layout/layout_scene',
						DialogicUtil.get_default_layout_scene())

		scene = load(scene_path).instantiate()
		scene.set_meta('scene_path', scene_path)

		get_parent().call_deferred("add_child", scene)
		get_tree().set_meta('dialogic_layout_node', scene)

	return scene


## Method to start a timeline without adding a layout scene.
## @timeline can be either a loaded timeline resource or a path to a timeline file.
## @label_or_idx can be a label (string) or index (int) to skip to immediatly.
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


## Preloader function, prepares a timeline and returns an object to hold for later
# TODO: Question: why is this taking a variant and then only allowing a string?
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
	clear(ClearFlags.TIMLEINE_INFO_ONLY)
	timeline_ended.emit()


func handle_next_event(ignore_argument:Variant = "") -> void:
	handle_event(current_event_idx+1)


func handle_event(event_index:int) -> void:
	if not current_timeline:
		return

	if has_meta('previous_event') and get_meta('previous_event') is DialogicEvent and get_meta('previous_event').event_finished.is_connected(handle_next_event):
		get_meta('previous_event').event_finished.disconnect(handle_next_event)

	if paused:
		await dialogic_resumed

	if event_index >= len(current_timeline_events):
		end_timeline()
		return

	#actually process the event now, since we didnt earlier at runtime
	#this needs to happen before we create the copy DialogicEvent variable, so it doesn't throw an error if not ready
	if current_timeline_events[event_index]['event_node_ready'] == false:
		current_timeline_events[event_index]._load_from_string(current_timeline_events[event_index]['event_node_as_text'])

	current_event_idx = event_index

	if not current_timeline_events[event_index].event_finished.is_connected(handle_next_event):
		current_timeline_events[event_index].event_finished.connect(handle_next_event)

	set_meta('previous_event', current_timeline_events[event_index])

	current_timeline_events[event_index].execute(self)
	event_handled.emit(current_timeline_events[event_index])


## Resets dialogics state fully or partially.
## By using the clear flags you can specify what info should be kept.
## For example at timeline end usually it doesn't clear node or subsystem info
func clear(clear_flags:=ClearFlags.FULL_CLEAR) -> bool:

	if !clear_flags & ClearFlags.TIMLEINE_INFO_ONLY:
		for subsystem in get_children():
			subsystem.clear_game_state(clear_flags)

	# Resetting variables
	current_timeline = null
	current_event_idx = -1
	current_timeline_events = []
	current_state = States.IDLE
	return true

#endregion


#region SAVING & LOADING
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

	## The Style subsystem needs to run first for others to load correctly.
	if has_subsystem('Style'):
		get_subsystem('Style').load_full_state()

	await get_tree().process_frame

	for subsystem in get_children():
		if subsystem.name == 'Style':
			continue

		subsystem.load_game_state()

#endregion


#region SUB-SYTSEMS
################################################################################

func collect_subsystems() -> void:
	# This also builds the event script cache as well
	_event_script_cache = []

	var subsystem_nodes := [] as Array[DialogicSubsystem]
	for indexer in DialogicUtil.get_indexers():

		# build event cache
		for event in indexer._get_events():
			if not FileAccess.file_exists(event):
				continue
			if not 'event_end_branch.gd' in event and not 'event_text.gd' in event:
				_event_script_cache.append(load(event).new())

		# build the subsystems (only at runtime)
		if !Engine.is_editor_hint():

			for subsystem in indexer._get_subsystems():
				var subsystem_node := add_subsystem(subsystem.name, subsystem.script)
				subsystem_nodes.push_back(subsystem_node)

	for subsystem in subsystem_nodes:
		subsystem.post_install()

	# Events are checked in order while testing them. EndBranch needs to be first, Text needs to be last
	_event_script_cache.push_front(DialogicEndBranchEvent.new())
	_event_script_cache.push_back(DialogicTextEvent.new())
	Engine.get_main_loop().set_meta("dialogic_event_cache", _event_script_cache)


func has_subsystem(_name:String) -> bool:
	return has_node(_name)


func get_subsystem(_name:String) -> Variant:
	return get_node(_name)


func add_subsystem(_name:String, _script_path:String) -> DialogicSubsystem:
	var node:Node = Node.new()
	node.name = _name
	node.set_script(load(_script_path))
	assert(node is DialogicSubsystem)
	node.dialogic = self
	add_child(node)
	return node as DialogicSubsystem


func _get(property):
	if has_subsystem(property):
		return get_node(str(property))


func _set(property, value):
	if has_subsystem(property):
		return true

#endregion


#region CHARACTER & TIMELINE DIRECTORIES
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

#endregion


#region HELPERS
################################################################################

func has_active_layout_node() -> bool:
	return (
		get_tree().has_meta('dialogic_layout_node')
		and is_instance_valid(get_tree().get_meta('dialogic_layout_node'))
		and get_tree().get_meta('dialogic_layout_node').visible
	)


func get_layout_node() -> Node:
	# `null` doesn't really work as a default for `get_meta`, because it'll
	# still throw an error if the meta entry doesn't exist. Revisit this if
	# Godot ever gives us a way to explicitly have `null` as a default.
	# (oddfacade 2023-07)
	var tree := get_tree()
	return (
		tree.get_meta('dialogic_layout_node')
		if tree.has_meta('dialogic_layout_node') and
			is_instance_valid(tree.get_meta('dialogic_layout_node'))
		else null
	)


func _on_timeline_ended():
	if is_instance_valid(get_tree().get_meta('dialogic_layout_node', '')):
		match ProjectSettings.get_setting('dialogic/layout/end_behaviour', 0):
			0:
				get_tree().get_meta('dialogic_layout_node', '').queue_free()
			1:
				get_tree().get_meta('dialogic_layout_node', '').hide()

#endregion Helpers
