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


#region INITIALIZE
####################################################################################################

func _ready() -> void:
	dialogic.event_handled.connect(store_full_event)
	dialogic.event_handled.connect(check_already_read)

	simple_history_enabled = ProjectSettings.get_setting('dialogic/history/simple_history_enabled', false)
	full_event_history_enabled = ProjectSettings.get_setting('dialogic/history/full_history_enabled', false)
	already_read_history_enabled = ProjectSettings.get_setting('dialogic/history/already_read_history_enabled', false)


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

## Called on each event
func store_full_event(event:DialogicEvent) -> void:
	if !full_event_history_enabled: return
	full_event_history_content.append(event)
	full_event_history_changed.emit()


#region ALREADY READ HISTORY
####################################################################################################

## Takes the current timeline event and creates a unique key for it.
## Uses the timeline resource path as well.
func _current_event_key() -> String:
	var resource_path = dialogic.current_timeline.resource_path
	var event_idx = str(dialogic.current_event_idx)
	var event_key = resource_path+event_idx

	return event_key

# Called if a Text event marks an unread Text event as read.
func event_was_read(_event: DialogicEvent) -> void:
	if !already_read_history_enabled:
		return

	var event_key = _current_event_key()

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

	var event_key = _current_event_key()

	if event_key in already_read_history_content:
		already_read_event_reached.emit()
		_was_last_event_already_read = true
	else:
		not_read_event_reached.emit()
		_was_last_event_already_read = false

func was_last_event_already_read() -> bool:
	return _was_last_event_already_read

#endregion
