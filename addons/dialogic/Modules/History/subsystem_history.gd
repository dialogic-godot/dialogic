extends DialogicSubsystem

## Subsystem that manages history storing.

signal open_requested
signal close_requested


## Simple history that stores limited information
## Used for the history display
var simple_history_enabled := false
var simple_history_save := false
var simple_history_content : Array[Dictionary] = []
signal simple_history_changed

## Whether to keep a history of every Dialogic event encountered.
var full_event_history_enabled := false
var full_event_history_save := false

## The full history of all Dialogic events encountered.
## Requires [member full_event_history_enabled] to be true.
var full_event_history_content: Array[DialogicEvent] = []

## Emitted if a new event has been inserted into the full event history.
signal full_event_history_changed

## Read text history
## Stores which text events and choices have already been visited
var visited_event_history_enabled := false

## A history of visited Dialogic events.
var visited_event_history_content := {}

## Whether the last event has been encountered for the first time.
var _visited_last_event := false

## Emitted if an encountered timeline event has been inserted into the visited
## event history.
##
## This will trigger only once per unique event instance.
signal visited_event

## Emitted if an encountered timeline event has not been visited before.
signal unvisited_event

## Used to store [member visited_event_history_content] in the global info file.
## You can change this to a custom name if you want to use a different key
## in the global save info file.
var visited_event_save_key := "visited_event_history_content"

## Whether to automatically save the already-visited history on auto-save.
var save_visited_history_on_autosave := false:
	set(value):
		save_visited_history_on_autosave = value
		_update_saved_connection(value)


## Whether to automatically save the already-visited history on manual save.
var save_visited_history_on_save := false:
	set(value):
		save_visited_history_on_save = value
		_update_saved_connection(value)


## Starts and stops the connection to the [subsystem Save] subsystem's [signal saved] signal.
func _update_saved_connection(to_connect: bool) -> void:
	if to_connect:
		if not DialogicUtil.autoload().Save.saved.is_connected(_on_save):
			DialogicUtil.autoload().Save.saved.connect(_on_save)

	else:
		if DialogicUtil.autoload().Save.saved.is_connected(_on_save):
			DialogicUtil.autoload().Save.saved.disconnect(_on_save)


#region INITIALIZE
####################################################################################################

func _ready() -> void:
	dialogic.event_handled.connect(store_full_event)
	dialogic.event_handled.connect(_check_seen)

	simple_history_enabled = ProjectSettings.get_setting('dialogic/history/simple_history_enabled', simple_history_enabled)
	simple_history_save = ProjectSettings.get_setting('dialogic/history/simple_history_save', simple_history_save)
	full_event_history_enabled = ProjectSettings.get_setting('dialogic/history/full_history_enabled', full_event_history_enabled)
	full_event_history_save = ProjectSettings.get_setting('dialogic/history/full_history_save', full_event_history_save)
	visited_event_history_enabled = ProjectSettings.get_setting('dialogic/history/visited_event_history_enabled', visited_event_history_enabled)



func _on_save(info: Dictionary) -> void:
	var is_autosave: bool = info["is_autosave"]

	var save_on_autosave := save_visited_history_on_autosave and is_autosave
	var save_on_save := save_visited_history_on_save and not is_autosave

	if save_on_save or save_on_autosave:
		save_visited_history()


func post_install() -> void:
	save_visited_history_on_autosave = ProjectSettings.get_setting('dialogic/history/save_on_autosave', save_visited_history_on_autosave)
	save_visited_history_on_save = ProjectSettings.get_setting('dialogic/history/save_on_save', save_visited_history_on_save)


func clear_game_state(clear_flag := DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	if clear_flag == DialogicGameHandler.ClearFlags.FULL_CLEAR:
		if simple_history_save:
			simple_history_content = []
			dialogic.current_state_info.erase("history_simple")
		if full_event_history_save:
			full_event_history_content = []
			dialogic.current_state_info.erase("history_full")


func load_game_state(load_flag := LoadFlags.FULL_LOAD) -> void:
	if load_flag == LoadFlags.FULL_LOAD:
		if simple_history_save and dialogic.current_state_info.has("history_simple"):
			simple_history_content.assign(dialogic.current_state_info["history_simple"])

		if full_event_history_save and dialogic.current_state_info.has("history_full"):
			full_event_history_content = []

			for event_text in dialogic.current_state_info["history_full"]:
				var event: DialogicEvent
				for i in DialogicResourceUtil.get_event_cache():
					if i.is_valid_event(event_text):
						event = i.duplicate()
						break
				event.from_text(event_text)
				full_event_history_content.append(event)


func save_game_state() -> void:
	if simple_history_save:
		dialogic.current_state_info["history_simple"] = Array(simple_history_content)
	else:
		dialogic.current_state_info.erase("history_simple")
	if full_event_history_save:
		dialogic.current_state_info["history_full"] = []
		for event in full_event_history_content:
			dialogic.current_state_info["history_full"].append(event.to_text())
	else:
		dialogic.current_state_info.erase("history_full")


func open_history() -> void:
	open_requested.emit()


func close_history() -> void:
	close_requested.emit()

#endregion


#region SIMPLE HISTORY
####################################################################################################

func store_simple_history_entry(text:String, event_type:String, extra_info := {}) -> void:
	if !simple_history_enabled: return
	extra_info['text'] = text
	extra_info['event_type'] = event_type
	simple_history_content.append(extra_info)
	simple_history_changed.emit()


func get_simple_history() -> Array:
	return simple_history_content

#endregion


#region FULL EVENT HISTORY
####################################################################################################

## Called on each event.
func store_full_event(event: DialogicEvent) -> void:
	if !full_event_history_enabled: return
	full_event_history_content.append(event)
	full_event_history_changed.emit()


#region ALREADY READ HISTORY
####################################################################################################

## Takes the current timeline event and creates a unique key for it.
## Uses the timeline resource path as well.
func _current_event_key() -> String:
	var resource_path := dialogic.current_timeline.resource_path
	var event_index := dialogic.current_event_idx
	var event_key := _get_event_key(event_index, resource_path)

	return event_key

## Composes an event key from the event index and the timeline path.
## If either of these variables are in an invalid state, the resulting
## key may be wrong.
## There are no safety checks in place.
func _get_event_key(event_index: int, timeline_path: String) -> String:
	var event_idx := str(event_index)
	var event_key := timeline_path + event_idx

	return event_key


## Called if an event is marked as visited.
func mark_event_as_visited(event_index := dialogic.current_event_idx, timeline := dialogic.current_timeline) -> void:
	if !visited_event_history_enabled:
		return

	var event_key := _get_event_key(event_index, timeline.resource_path)

	visited_event_history_content[event_key] = event_index


## Called on each event, but we filter for Text events.
func _check_seen(event: DialogicEvent) -> void:
	if !visited_event_history_enabled:
		return

	# At this point, we only care about Text events.
	# There may be a more elegant way of filtering events.
	# Especially since custom events require this event name.
	if event.event_name != "Text":
		return

	var event_key := _current_event_key()

	if event_key in visited_event_history_content:
		visited_event.emit()
		_visited_last_event = true

	else:
		unvisited_event.emit()
		_visited_last_event = false


## Whether the last event has been visited for the first time or not.
## This will return `true` exactly once for each unique timeline event instance.
func has_last_event_been_visited() -> bool:
	return _visited_last_event


## If called with with no arguments, the method will return whether
## the last encountered event was visited before.
##
## Otherwise, if [param event_index] and [param timeline] are passed,
## the method will check if the event from that given timeline has been
## visited yet.
##
## If no [param timeline] is passed, the current timeline will be used.
## If there is no current timeline, `false` will be returned.
##
## If no [param event_index] is passed, the current event index will be used.
func has_event_been_visited(event_index := dialogic.current_event_idx, timeline := dialogic.current_timeline) -> bool:
	if timeline == null:
		return false

	var event_key := _get_event_key(event_index, timeline.resource_path)
	var visited := event_key in visited_event_history_content

	return visited


## Saves all seen events to the global info file.
## This can be useful when the player saves the game.
## In visual novels, callings this at the end of a route can be useful, as the
## player may not save the game.
##
## Be aware, this won't add any events but completely overwrite the already saved ones.
##
## Relies on the [subsystem Save] subsystem.
func save_visited_history() -> void:
	DialogicUtil.autoload().Save.set_global_info(visited_event_save_key, visited_event_history_content)


## Loads the seen events from the global info save file.
## Calling this when a game gets loaded may be useful.
##
## Relies on the [subsystem Save] subsystem.
func load_visited_history() -> void:
	visited_event_history_content = get_saved_visited_history()


## Returns the saved already-visited history from the global info save file.
## If none exist in the global info file, returns an empty dictionary.
##
## Relies on the [subsystem Save] subsystem.
func get_saved_visited_history() -> Dictionary:
	return DialogicUtil.autoload().Save.get_global_info(visited_event_save_key, {})


## Resets the already-visited history in the global info save file.
## If [param reset_property] is true, it will also reset the already-visited
## history in the Dialogic Autoload.
##
## Relies on the [subsystem Save] subsystem.
func reset_visited_history(reset_property := true) -> void:
	DialogicUtil.autoload().Save.set_global_info(visited_event_save_key, {})

	if reset_property:
		visited_event_history_content = {}

#endregion
