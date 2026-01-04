class_name DialogicGameHandler
extends Node

## Class that is used as the Dialogic autoload.

## Autoload script that allows you to interact with all of Dialogic's systems:[br]
## - Holds all important information about the current state of Dialogic.[br]
## - Provides access to all the subsystems.[br]
## - Has methods to start/end timelines.[br]


## States indicating different phases of dialog.
enum States {
	IDLE, 				## Dialogic is awaiting input to advance.
	REVEALING_TEXT, 	## Dialogic is currently revealing text.
	ANIMATING, 			## Some animation is happening.
	AWAITING_CHOICE, 	## Dialogic awaits the selection of a choice
	WAITING 			## Dialogic is currently awaiting something.
	}

## Flags indicating what to clear when calling [method clear].
enum ClearFlags {
	FULL_CLEAR = 0, 		## Clears all subsystems
	KEEP_VARIABLES = 1, 	## Clears all subsystems and info except for variables
	TIMELINE_INFO_ONLY = 2	## Doesn't clear subsystems but current timeline and index
	}

## Reference to the currently executed timeline.
var current_timeline: DialogicTimeline = null
## Copy of the [member current_timeline]'s events.
var current_timeline_events: Array = []

## Index of the event the timeline handling is currently at.
var current_event_idx: int = 0
## Contains all information that subsystems consider relevant for
## the current situation
var current_state_info: Dictionary = {}

## Current state (see [member States] enum).
var current_state := States.IDLE:
	get:
		return current_state

	set(new_state):
		current_state = new_state
		state_changed.emit(new_state)

## Emitted when [member current_state] change.
signal state_changed(new_state:States)

## When `true`, many dialogic processes won't continue until it's `false` again.
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

## A timeline that will be played when dialog ends.
## By default this timeline only contains a clear event.
var dialog_ending_timeline: DialogicTimeline

## Emitted when [member paused] changes to `true`.
signal dialogic_paused
## Emitted when [member paused] changes to `false`.
signal dialogic_resumed


## Emitted when a timeline starts by calling either [method start]
## or [method start_timeline].
signal timeline_started
## Emitted when the timeline ends.
## This can be a timeline ending or [method end_timeline] being called.
signal timeline_ended
## Emitted when an event starts being executed.
## The event may not have finished executing yet.
signal event_handled(resource: DialogicEvent)

## Emitted when a [class SignalEvent] event was reached.
@warning_ignore("unused_signal") # This is emitted by the signal event.
signal signal_event(argument: Variant)

## Emitted when a signal event gets fired from a [class TextEvent] event.
@warning_ignore("unused_signal") # This is emitted by the text subsystem.
signal text_signal(argument: String)


# Careful, this section is repopulated automatically at certain moments.
#region SUBSYSTEMS

var Animations := preload("res://addons/dialogic/Modules/Core/subsystem_animation.gd").new():
	get: return get_subsystem("Animations")

var Audio := preload("res://addons/dialogic/Modules/Audio/subsystem_audio.gd").new():
	get: return get_subsystem("Audio")

var Backgrounds := preload("res://addons/dialogic/Modules/Background/subsystem_backgrounds.gd").new():
	get: return get_subsystem("Backgrounds")

var Choices := preload("res://addons/dialogic/Modules/Choice/subsystem_choices.gd").new():
	get: return get_subsystem("Choices")

var Expressions := preload("res://addons/dialogic/Modules/Core/subsystem_expression.gd").new():
	get: return get_subsystem("Expressions")

var Glossary := preload("res://addons/dialogic/Modules/Glossary/subsystem_glossary.gd").new():
	get: return get_subsystem("Glossary")

var History := preload("res://addons/dialogic/Modules/History/subsystem_history.gd").new():
	get: return get_subsystem("History")

var Inputs := preload("res://addons/dialogic/Modules/Core/subsystem_input.gd").new():
	get: return get_subsystem("Inputs")

var Jump := preload("res://addons/dialogic/Modules/Jump/subsystem_jump.gd").new():
	get: return get_subsystem("Jump")

var PortraitContainers := preload("res://addons/dialogic/Modules/Character/subsystem_containers.gd").new():
	get: return get_subsystem("PortraitContainers")

var Portraits := preload("res://addons/dialogic/Modules/Character/subsystem_portraits.gd").new():
	get: return get_subsystem("Portraits")

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
	_collect_subsystems()

	clear()

	DialogicResourceUtil.update_event_cache()

	dialog_ending_timeline = DialogicTimeline.new()
	dialog_ending_timeline.from_text("[clear]")


#region TIMELINE & EVENT HANDLING
################################################################################

## Method to start a timeline AND ensure that a layout scene is present.
## For argument info, checkout [method start_timeline].
## -> returns the layout node
func start(timeline:Variant, label_or_idx:Variant="") -> Node:
	# If we don't have a style subsystem, default to just start_timeline()
	if not has_subsystem('Styles'):
		printerr("[Dialogic] You called Dialogic.start() but the Styles subsystem is missing!")
		clear(ClearFlags.KEEP_VARIABLES)
		start_timeline(timeline, label_or_idx)
		return null

	# Otherwise make sure there is a style active.
	var scene: Node = null
	if not self.Styles.has_active_layout_node():
		scene = self.Styles.load_style()
	else:
		scene = self.Styles.get_layout_node()
		scene.show()

	if not scene.is_node_ready():
		if not scene.ready.is_connected(clear.bind(ClearFlags.KEEP_VARIABLES)):
			scene.ready.connect(clear.bind(ClearFlags.KEEP_VARIABLES))
		if not scene.ready.is_connected(start_timeline.bind(timeline, label_or_idx)):
			scene.ready.connect(start_timeline.bind(timeline, label_or_idx))
	else:
		start_timeline(timeline, label_or_idx)

	return scene


## Method to start a timeline without adding a layout scene.
## @timeline can be either a loaded timeline resource or a path to a timeline file.
## @label_or_idx can be a label (string) or index (int) to skip to immediatly.
func start_timeline(timeline:Variant, label_or_idx:Variant = "") -> void:
	# load the resource if only the path is given
	if typeof(timeline) in [TYPE_STRING, TYPE_STRING_NAME]:
		#check the lookup table if it's not a full file name
		if "://" in timeline:
			timeline = load(timeline)
		else:
			timeline = DialogicResourceUtil.get_timeline_resource(timeline)

	if timeline == null:
		printerr("[Dialogic] There was an error loading this timeline. Check the filename, and the timeline for errors")
		return

	(timeline as DialogicTimeline).process()

	current_timeline = timeline
	current_timeline_events = current_timeline.events
	for event in current_timeline_events:
		event.dialogic = self
	current_event_idx = -1

	if typeof(label_or_idx) in [TYPE_STRING, TYPE_STRING_NAME]:
		if label_or_idx:
			if has_subsystem('Jump'):
				Jump.jump_to_label((label_or_idx as String))
	elif typeof(label_or_idx) == TYPE_INT:
		if label_or_idx >-1:
			current_event_idx = label_or_idx -1

	if not current_timeline == dialog_ending_timeline:
		timeline_started.emit()

	handle_next_event()


## Preloader function, prepares a timeline and returns an object to hold for later
## [param timeline_resource] can be either a path (string) or a loaded timeline (resource)
func preload_timeline(timeline_resource:Variant) -> Variant:
	# I think ideally this should be on a new thread, will test
	if typeof(timeline_resource) in [TYPE_STRING, TYPE_STRING_NAME]:
		if "://" in timeline_resource:
			timeline_resource = load(timeline_resource)
		else:
			timeline_resource = DialogicResourceUtil.get_timeline_resource(timeline_resource)

		if timeline_resource == null:
			printerr("[Dialogic] There was an error preloading this timeline. Check the filename, and the timeline for errors")
			return null

	(timeline_resource as DialogicTimeline).process()

	return timeline_resource


## Clears and stops the current timeline.
## If [param skip_ending] is `true`, the dialog_ending_timeline is not getting played
func end_timeline(skip_ending := false) -> void:
	if not skip_ending and dialog_ending_timeline and current_timeline != dialog_ending_timeline:
		start(dialog_ending_timeline)
		return

	await clear(ClearFlags.TIMELINE_INFO_ONLY)

	if Styles.has_active_layout_node() and Styles.get_layout_node().is_inside_tree():
		match ProjectSettings.get_setting('dialogic/layout/end_behaviour', 0):
			0:
				Styles.get_layout_node().get_parent().remove_child(Styles.get_layout_node())
				Styles.get_layout_node().queue_free()
			1:
				Styles.get_layout_node().hide()

	timeline_ended.emit()


## Method to check if timeline exists.
## @timeline can be either a loaded timeline resource or a path to a timeline file.
func timeline_exists(timeline:Variant) -> bool:
	if typeof(timeline) in [TYPE_STRING, TYPE_STRING_NAME]:
		if "://" in timeline and ResourceLoader.exists(timeline):
			return load(timeline) is DialogicTimeline
		else:
			return DialogicResourceUtil.timeline_resource_exists(timeline)

	return timeline is DialogicTimeline


## Handles the next event.
func handle_next_event(_ignore_argument: Variant = "") -> void:
	handle_event(current_event_idx+1)


## Handles the event at the given index [param event_index].
## You can call this manually, but if another event is still executing, it might have unexpected results.
func handle_event(event_index:int) -> void:
	if not current_timeline:
		return

	_cleanup_previous_event()

	if paused:
		await dialogic_resumed

	if event_index >= len(current_timeline_events):
		end_timeline()
		return

	# TODO: Check if necessary. This should be impossible.
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


## Resets Dialogic's state fully or partially.
## By using the clear flags from the [member ClearFlags] enum you can specify
## what info should be kept.
## For example, at timeline end usually it doesn't clear node or subsystem info.
func clear(clear_flags := ClearFlags.FULL_CLEAR) -> void:
	_cleanup_previous_event()

	if !clear_flags & ClearFlags.TIMELINE_INFO_ONLY:
		for subsystem in get_children():
			if subsystem is DialogicSubsystem:
				(subsystem as DialogicSubsystem).clear_game_state(clear_flags)

	var timeline := current_timeline

	current_timeline = null
	current_event_idx = -1
	current_timeline_events = []
	current_state = States.IDLE

	# Resetting variables
	if timeline:
		await timeline.clean()


## Cleanup after previous event (if any).
func _cleanup_previous_event():
	if has_meta('previous_event') and get_meta('previous_event') is DialogicEvent:
		var event := get_meta('previous_event') as DialogicEvent
		if event.event_finished.is_connected(handle_next_event):
			event.event_finished.disconnect(handle_next_event)
		event._clear_state()
		remove_meta("previous_event")

#endregion


#region SAVING & LOADING
################################################################################

## Returns a dictionary containing all necessary information to later recreate the same state with load_full_state.
## The [subsystem Save] subsystem might be more useful for you.
## However, this can be used to integrate the info into your own save system.
func get_full_state() -> Dictionary:
	if current_timeline:
		current_state_info['current_event_idx'] = current_event_idx
		current_state_info['current_timeline'] = current_timeline.resource_path
	else:
		current_state_info['current_event_idx'] = -1
		current_state_info['current_timeline'] = null

	for subsystem in get_children():
		(subsystem as DialogicSubsystem).save_game_state()

	return current_state_info.duplicate(true)


## This method tries to load the state from the given [param state_info].
## Will automatically start a timeline and add a layout if a timeline was running when
## the dictionary was retrieved with [method get_full_state].
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
	else:
		end_timeline.call_deferred(true)
#endregion


#region SUB-SYTSEMS
################################################################################

func _collect_subsystems() -> void:
	var subsystem_nodes := [] as Array[DialogicSubsystem]
	for indexer in DialogicUtil.get_indexers():
		for subsystem in indexer._get_subsystems():
			var subsystem_node := add_subsystem(str(subsystem.name), str(subsystem.script))
			subsystem_nodes.push_back(subsystem_node)

	for subsystem in subsystem_nodes:
		subsystem.post_install()


## Returns `true` if a subystem with the given [param subsystem_name] exists.
func has_subsystem(subsystem_name:String) -> bool:
	return has_node(subsystem_name)


## Returns the subsystem node of the given [param subsystem_name] or null if it doesn't exist.
func get_subsystem(subsystem_name:String) -> DialogicSubsystem:
	return get_node(subsystem_name)


## Adds a subsystem node with the given [param subsystem_name] and [param script_path].
func add_subsystem(subsystem_name:String, script_path:String) -> DialogicSubsystem:
	var node: Node = Node.new()
	node.name = subsystem_name
	node.set_script(load(script_path))
	node = node as DialogicSubsystem
	node.dialogic = self
	add_child(node)
	return node


#endregion


#region HELPERS
################################################################################



func print_debug_moment() -> void:
	if not current_timeline:
		return

	printerr("\tAt event ", current_event_idx+1, " (",current_timeline_events[current_event_idx].event_name, ' Event) in timeline "', current_timeline.get_identifier(), '" (',current_timeline.resource_path,').')
	print("\n")
#endregion
