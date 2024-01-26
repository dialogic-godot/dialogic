class_name DialogicGameHandler
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
signal state_changed(new_state:States)

## When true, many dialogic process won't continue until it's false again.
var paused := false:
	set(value):
		paused = value
		if paused:
			for subsystem in get_children():
				if subsystem is DialogicSubsystem:
					(subsystem as DialogicSubsystem).pause()
			dialogic_paused.emit()
		else:
			for subsystem in get_children():
				if subsystem is DialogicSubsystem:
					(subsystem as DialogicSubsystem).resume()
			dialogic_resumed.emit()

## Emitted when [paused] changes to true.
signal dialogic_paused
## Emitted when [paused] changes to false.
signal dialogic_resumed


signal timeline_ended
signal timeline_started
signal event_handled(resource:DialogicEvent)

## Emitted when the Signal event was reached
signal signal_event(argument:Variant)
## Emitted when [signal] effect was reached in text.
signal text_signal(argument:String)


# Careful, this section is repopulated automatically at certain moments
#region SUBSYSTEMS

var Audio := preload("res://addons/dialogic/Modules/Audio/subsystem_audio.gd").new():
	get: return get_subsystem("Audio")

var Backgrounds := preload("res://addons/dialogic/Modules/Background/subsystem_backgrounds.gd").new():
	get: return get_subsystem("Backgrounds")

var Portraits := preload("res://addons/dialogic/Modules/Character/subsystem_portraits.gd").new():
	get: return get_subsystem("Portraits")

var Choices := preload("res://addons/dialogic/Modules/Choice/subsystem_choices.gd").new():
	get: return get_subsystem("Choices")

var Expressions := preload("res://addons/dialogic/Modules/Core/subsystem_expression.gd").new():
	get: return get_subsystem("Expressions")

var Animations := preload("res://addons/dialogic/Modules/Core/subsystem_animation.gd").new():
	get: return get_subsystem("Animations")

var Inputs := preload("res://addons/dialogic/Modules/Core/subsystem_input.gd").new():
	get: return get_subsystem("Inputs")

var Glossary := preload("res://addons/dialogic/Modules/Glossary/subsystem_glossary.gd").new():
	get: return get_subsystem("Glossary")

var History := preload("res://addons/dialogic/Modules/History/subsystem_history.gd").new():
	get: return get_subsystem("History")

var Jump := preload("res://addons/dialogic/Modules/Jump/subsystem_jump.gd").new():
	get: return get_subsystem("Jump")

var Save := preload("res://addons/dialogic/Modules/Save/subsystem_save.gd").new():
	get: return get_subsystem("Save")

var Settings := preload("res://addons/dialogic/Modules/Settings/subsystem_settings.gd").new():
	get: return get_subsystem("Settings")

var Styles := preload("res://addons/dialogic/Modules/Style/subsystem_styles.gd").new():
	get: return get_subsystem("Styles")

var Text := preload("res://addons/dialogic/Modules/Text/subsystem_text.gd").new():
	get: return get_subsystem("Text")

var TextInput := preload("res://addons/dialogic/Modules/TextInput/subsystem_text_input.gd").new():
	get: return get_subsystem("TextInput")

var VAR := preload("res://addons/dialogic/Modules/Variable/subsystem_variables.gd").new():
	get: return get_subsystem("VAR")

var Voice := preload("res://addons/dialogic/Modules/Voice/subsystem_voice.gd").new():
	get: return get_subsystem("Voice")

#endregion

## Autoloads are added first, so this happens REALLY early on game startup.
func _ready() -> void:
	DialogicResourceUtil.update()

	collect_subsystems()

	clear()

	timeline_ended.connect(_on_timeline_ended)


#region TIMELINE & EVENT HANDLING
################################################################################

## Method to start a timeline AND ensure that a layout scene is present.
## For argument info, checkout start_timeline()
## -> returns the layout node
func start(timeline:Variant, label:Variant="") -> Node:
	# If we don't have a style subsystem, default to just start_timeline()
	if !has_subsystem('Styles'):
		printerr("[Dialogic] You called Dialogic.start() but the Styles subsystem is missing!")
		clear(ClearFlags.KEEP_VARIABLES)
		start_timeline(timeline, label)
		return null

	# Otherwise make sure there is a style active.
	var scene: Node= null
	if !self.Styles.has_active_layout_node():
		scene = self.Styles.load_style()
	else:
		scene = self.Styles.get_layout_node()

	if not scene.is_node_ready():
		scene.ready.connect(clear.bind(ClearFlags.KEEP_VARIABLES))
		scene.ready.connect(start_timeline.bind(timeline, label))
	else:
		clear(ClearFlags.KEEP_VARIABLES)
		start_timeline(timeline, label)

	return scene


## Method to start a timeline without adding a layout scene.
## @timeline can be either a loaded timeline resource or a path to a timeline file.
## @label_or_idx can be a label (string) or index (int) to skip to immediatly.
func start_timeline(timeline:Variant, label_or_idx:Variant = "") -> void:
	# load the resource if only the path is given
	if typeof(timeline) == TYPE_STRING:
		#check the lookup table if it's not a full file name
		if (timeline as String).contains("res://"):
			timeline = load((timeline as String))
		else:
			timeline = DialogicResourceUtil.get_timeline_resource((timeline as String))

	if timeline == null:
		printerr("[Dialogic] There was an error loading this timeline. Check the filename, and the timeline for errors")
		return

	await (timeline as DialogicTimeline).process()

	current_timeline = timeline
	current_timeline_events = current_timeline.events
	current_event_idx = -1

	if typeof(label_or_idx) == TYPE_STRING:
		if label_or_idx:
			if has_subsystem('Jump'):
				Jump.jump_to_label((label_or_idx as String))
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
		timeline_resource = load((timeline_resource as String))
		if timeline_resource == null:
			printerr("[Dialogic] There was an error preloading this timeline. Check the filename, and the timeline for errors")
			return false
		else:
			await (timeline_resource as DialogicTimeline).process()
			return timeline_resource
	return null


func end_timeline() -> void:
	clear(ClearFlags.TIMLEINE_INFO_ONLY)
	timeline_ended.emit()


func handle_next_event(ignore_argument:Variant = "") -> void:
	handle_event(current_event_idx+1)


func handle_event(event_index:int) -> void:
	if not current_timeline:
		return

	if has_meta('previous_event') and get_meta('previous_event') is DialogicEvent and (get_meta('previous_event') as DialogicEvent).event_finished.is_connected(handle_next_event):
		(get_meta('previous_event') as DialogicEvent).event_finished.disconnect(handle_next_event)

	if paused:
		await dialogic_resumed

	if event_index >= len(current_timeline_events):
		end_timeline()
		return

	#actually process the event now, since we didnt earlier at runtime
	#this needs to happen before we create the copy DialogicEvent variable, so it doesn't throw an error if not ready
	if current_timeline_events[event_index].event_node_ready == false:
		current_timeline_events[event_index]._load_from_string(current_timeline_events[event_index].event_node_as_text)

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
			if subsystem is DialogicSubsystem:
				(subsystem as DialogicSubsystem).clear_game_state(clear_flags)

	# Resetting variables
	if current_timeline:
		current_timeline.clean()
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
	## The Style subsystem needs to run first for others to load correctly.
	var scene: Node = null
	if has_subsystem('Styles'):
		get_subsystem('Styles').load_game_state()
		scene = self.Styles.get_layout_node()


	var load_subsystems := func() -> void:
		for subsystem in get_children():
			if subsystem.name == 'Styles':
				continue
			(subsystem as DialogicSubsystem).load_game_state()

	if null != scene and not scene.is_node_ready():
		scene.ready.connect(load_subsystems)
	else:
		await get_tree().process_frame
		load_subsystems.call()

	if current_state_info.get('current_timeline', null):
		start_timeline(current_state_info.current_timeline, current_state_info.get('current_event_idx', 0))

#endregion


#region SUB-SYTSEMS
################################################################################

func collect_subsystems() -> void:
	var subsystem_nodes := [] as Array[DialogicSubsystem]
	for indexer in DialogicUtil.get_indexers():
		for subsystem in indexer._get_subsystems():
			var subsystem_node := add_subsystem(str(subsystem.name), str(subsystem.script))
			subsystem_nodes.push_back(subsystem_node)

	for subsystem in subsystem_nodes:
		subsystem.post_install()


func has_subsystem(_name:String) -> bool:
	return has_node(_name)


func get_subsystem(_name:String) -> DialogicSubsystem:
	return get_node(_name)


func add_subsystem(_name:String, _script_path:String) -> DialogicSubsystem:
	var node: Node = Node.new()
	node.name = _name
	node.set_script(load(_script_path))
	node = node as DialogicSubsystem
	node.dialogic = self
	add_child(node)
	return node


#endregion


#region HELPERS
################################################################################

func _on_timeline_ended() -> void:
	if is_instance_valid(get_tree().get_meta('dialogic_layout_node', '')):
		match ProjectSettings.get_setting('dialogic/layout/end_behaviour', 0):
			0:
				(get_tree().get_meta('dialogic_layout_node', '') as Node).queue_free()
			1:
				@warning_ignore("unsafe_method_access")
				get_tree().get_meta('dialogic_layout_node', '').hide()

#endregion
