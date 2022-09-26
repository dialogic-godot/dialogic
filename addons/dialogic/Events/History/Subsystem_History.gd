extends DialogicSubsystem

var enabled:bool = true

var full_history_enabled:bool = true
var full_history_length:int = 50

var text_read_history_enabled:bool = true

var full_history:Array = []

var text_read_history:Dictionary = {}

####################################################################################################
##					STATE
####################################################################################################

func clear_game_state() -> void:
	pass

func load_game_state() -> void:
	pass

####################################################################################################
##					MAIN METHODS
####################################################################################################

func add_event_to_history(current_timeline:String, current_index:int, current_event:DialogicEvent) -> void:
	if full_history_enabled:
		var event_dict:Dictionary = {}
		event_dict['timeline'] = current_timeline
		event_dict['index'] = current_index
		event_dict['event_object'] = current_event
		event_dict['event_type'] = current_event.event_name
		
		#A few more specific types of checks need to happen here to capture previous values
		
		full_history.push_front(event_dict)
		if full_history.size() > full_history_length:
			var dropped = full_history.pop_back()
		
	if text_read_history_enabled:
		if current_event.event_name == "Text":
			text_read_history[str(current_index)+ "**" + current_timeline] = true

func strip_events_from_full_history() -> void:
	for i in full_history.size():
		full_history[i].erase('event_object')
		
func rebuild_all_history_events() -> void:
	pass
