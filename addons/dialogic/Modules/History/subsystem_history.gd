extends DialogicSubsystem

## Subsystem that manages history storing.

signal open_requested
signal close_requested


## Simple history that stores limited information
## Used for the history display
var simple_history_enabled := true
var simple_history_content : Array[Dictionary] = []
signal simple_history_changed

## Full event history (can be used for undo)
var full_event_history_enabled := false
var full_event_history_content := []
signal full_event_history_changed

## Read text history
## Stores which text events and choices have already been visited
var already_read_history_enabled := false
var already_read_history_content := {}
var _was_last_event_already_read := false

signal already_read_event_reached
signal not_read_event_reached

## Used to store [member already_read_history_content] in the global info file.
## You can change this to a custom name if you want to use a different key
## in the global save info file.
var already_seen_save_key := "already_read_history_content"

## Whether to automatically save the already-seen history on auto-save.
var save_already_seen_history_on_autosave := false:
	set(value):
		save_already_seen_history_on_autosave = value
		_update_saved_connection(value)


## Whether to automatically save the already-seen history on manual save.
var save_already_seen_history_on_save := false:
	set(value):
		save_already_seen_history_on_save = value
		_update_saved_connection(value)


## Starts and stops the connection to the Save subsystem's [signal saved] signal.
func _update_saved_connection(to_connect: bool) -> void:
	if to_connect:

		if not DialogicUtil.autoload().Save.saved.is_connected(_on_save):
			var _result := DialogicUtil.autoload().Save.saved.connect(_on_save)

	else:

		if DialogicUtil.autoload().Save.saved.is_connected(_on_save):
			DialogicUtil.autoload().Save.saved.disconnect(_on_save)


#region INITIALIZE
####################################################################################################

func _ready() -> void:
	var _result := dialogic.event_handled.connect(store_full_event)
	_result = dialogic.event_handled.connect(check_already_read)

	simple_history_enabled = ProjectSettings.get_setting('dialogic/history/simple_history_enabled', false)
	full_event_history_enabled = ProjectSettings.get_setting('dialogic/history/full_history_enabled', false)
	already_read_history_enabled = ProjectSettings.get_setting('dialogic/history/already_read_history_enabled', false)



func _on_save(info: Dictionary) -> void:
	var is_autosave: bool = info["is_autosave"]

	var save_on_autosave := save_already_seen_history_on_autosave and is_autosave
	var save_on_save := save_already_seen_history_on_save and not is_autosave

	if save_on_save or save_on_autosave:
		save_already_seen_history()


func post_install() -> void:
	save_already_seen_history_on_autosave = ProjectSettings.get_setting('dialogic/history/save_on_autosave', save_already_seen_history_on_autosave)
	save_already_seen_history_on_save = ProjectSettings.get_setting('dialogic/history/save_on_save', save_already_seen_history_on_save)


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
func store_full_event(event:DialogicEvent) -> void:
	if !full_event_history_enabled: return
	full_event_history_content.append(event)
	full_event_history_changed.emit()


#region ALREADY READ HISTORY
####################################################################################################

## Takes the current timeline event and creates a unique key for it.
## Uses the timeline resource path as well.
func _current_event_key() -> String:
	var resource_path := dialogic.current_timeline.resource_path
	var event_idx := str(dialogic.current_event_idx)
	var event_key := resource_path + event_idx

	return event_key

# Called if a Text event marks an unread Text event as read.
func event_was_read(_event: DialogicEvent) -> void:
	if !already_read_history_enabled:
		return

	var event_key := _current_event_key()

	already_read_history_content[event_key] = dialogic.current_event_idx

# Called on each event, but we filter for Text events.
func check_already_read(event: DialogicEvent) -> void:
	if !already_read_history_enabled:
		return

	# At this point, we only care about Text events.
	# There may be a more elegant way of filtering events.
	# Especially since custom events require this event name.
	if event.event_name != "Text":
		return

	var event_key := _current_event_key()

	if event_key in already_read_history_content:
		already_read_event_reached.emit()
		_was_last_event_already_read = true

	else:
		not_read_event_reached.emit()
		_was_last_event_already_read = false


func was_last_event_already_read() -> bool:
	return _was_last_event_already_read


## Saves all seen events to the global info file.
## This can be useful when the player saves the game.
## In visual novels, callings this at the end of a route can be useful, as the
## player may not save the game.
##
## Be aware, this won't add any events but completely overwrite the already saved ones.
##
## Relies on the Save subsystem.
func save_already_seen_history() -> void:
	DialogicUtil.autoload().Save.set_global_info(already_seen_save_key, already_read_history_content)


## Loads the seen events from the global info save file.
## Calling this when a game gets loaded may be useful.
##
## ## Relies on the Save subsystem.
func load_already_seen_history() -> void:
	already_read_history_content = DialogicUtil.autoload().Save.get_global_info(already_seen_save_key, {})


## Returns the saved already-seen history from the global info save file.
## If none exist in the global info file, returns an empty dictionary.
##
## ## Relies on the Save subsystem.
func get_saved_already_seen_history() -> Dictionary:
	return DialogicUtil.autoload().Save.get_global_info(already_seen_save_key, {})


## Resets the already-seen history in the global info save file.
## If [param reset_property] is true, it will also reset the already-seen
## history in the Dialogic Autoload.
##
## ## Relies on the Save subsystem.
func reset_already_seen_history(reset_property: bool) -> void:
	DialogicUtil.autoload().Save.set_global_info(already_seen_save_key, {})

	if reset_property:
		DialogicUtil.autoload().History.already_read_history_content = {}

#endregion
