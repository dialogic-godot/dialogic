extends DialogicSubsystem

## Subsystem that manages history storing.


signal history_text_already_read()


## Set from the settings at runtime. If false, no history will be saved.
var enabled: bool = true

## If true, all events will be stored with additional information. 
## Usefull if you want to be able to undo, or jump to certain points.  
## (Change from the settings).
var full_history_enabled: bool = true
var full_history_length: int = 50
var full_history_option_save_text: bool = false
## Stores the content of the full_history
var full_history: Array = []

## If true, all text and choices text will be saved to the history. (Change from the settings).
var text_read_history_enabled: bool = true
## Stores the content of the text_read_history
var text_read_history: Dictionary = {}



####################################################################################################
##					INITIALIZE
####################################################################################################

func _ready() -> void: 
	enabled = DialogicUtil.get_project_setting('dialogic/history/history_system', true)
	full_history_enabled = DialogicUtil.get_project_setting('dialogic/history/full_history', true)
	full_history_length = DialogicUtil.get_project_setting('dialogic/history/full_history_length', 50)
	full_history_option_save_text = DialogicUtil.get_project_setting('dialogic/history/full_history_option_save_text', false)
	text_read_history_enabled = DialogicUtil.get_project_setting('dialogic/history/text_history', true)


####################################################################################################
##					STATE
####################################################################################################

# nothing implemented right now

####################################################################################################
##					MAIN METHODS
####################################################################################################

func add_event_to_history(current_timeline:String, current_index:int, current_event:DialogicEvent) -> void:
	if full_history_enabled:
		var event_dict: Dictionary = {}
		event_dict['timeline'] = current_timeline
		event_dict['index'] = current_index
		event_dict['event_object'] = current_event
		event_dict['event_type'] = current_event.event_name
		
		#A few more specific types of checks need to happen here to capture previous values
		
		if current_event.event_name == "Text" and full_history_option_save_text:
			event_dict['text_event_character'] = current_event.character.get_character_name()
			event_dict['text_event_portrait'] = current_event.portrait
			event_dict['text_event_text'] = current_event.text
		
		full_history.push_front(event_dict)
		if full_history.size() > full_history_length:
			var dropped = full_history.pop_back()
		
	if text_read_history_enabled:
		if current_event.event_name == "Text" or current_event.event_name == "Choice":
			var line = str(current_index)+ "**" + current_timeline
			if line in text_read_history:
				emit_signal("history_text_already_read")
			else:	
				text_read_history[line] = true


func strip_events_from_full_history() -> void:
	for i in full_history.size():
		full_history[i].erase('event_object')


func rebuild_all_history_events() -> void:
	var temp_timelines: Dictionary = {} 
	for i in full_history.size():
		if full_history[i]['timeline'] in temp_timelines:
			full_history[i]['event_object'] = temp_timelines[full_history[i]['timeline']].events[full_history[i]['index']]
		else:
			var loaded_timeline = Dialogic.preload_timeline(full_history[i]['timeline'])
			temp_timelines[full_history[i]['timeline']] = loaded_timeline
			full_history[i]['event_object'] = loaded_timeline.events[full_history[i]['index']]
