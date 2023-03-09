extends DialogicSubsystem

## Subsystem that manages history storing.


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
signal already_read_event_reached
signal not_read_event_reached

####################################################################################################
##					INITIALIZE
####################################################################################################

func _ready() -> void: 
	Dialogic.event_handled.connect(store_full_event)
	Dialogic.event_handled.connect(check_already_read)
	
	simple_history_enabled = ProjectSettings.get_setting('dialogic/history/simple_history_enabled', false)
	full_event_history_enabled = ProjectSettings.get_setting('dialogic/history/full_history_enabled', false)
	already_read_history_enabled = ProjectSettings.get_setting('dialogic/history/already_read_history_enabled', false)


####################################################################################################
##					STATE
####################################################################################################

# nothing implemented right now

####################################################################################################
##					SIMPLE HISTORY
####################################################################################################

func store_simple_history_entry(text:String, event_type:String, extra_info := {}) -> void:
	if !simple_history_enabled: return
	extra_info['text'] = text
	extra_info['event_type'] = event_type
	simple_history_content.append(extra_info)
	simple_history_changed.emit()


func get_simple_history() -> Array:
	return simple_history_content



####################################################################################################
##					FULL EVENT HISTORY
####################################################################################################

# called on each event
func store_full_event(event:DialogicEvent) -> void:
	if !full_event_history_enabled: return
	full_event_history_content.append(event)
	full_event_history_changed.emit()


####################################################################################################
##					ALREADY READ HISTORY
####################################################################################################

func event_was_read(event:DialogicEvent) -> void:
	if !already_read_history_enabled: return
	already_read_history_content[Dialogic.current_timeline.resource_path+str(Dialogic.current_event_idx)] = Dialogic.current_event_idx


# called on each event 
func check_already_read(event:DialogicEvent) -> void:
	if !already_read_history_enabled: return
	if Dialogic.current_timeline.resource_path+str(Dialogic.current_event_idx) in already_read_history_content:
		already_read_event_reached.emit()
	else:
		not_read_event_reached.emit()
