extends DialogicSubsystem

var enabled:bool = true

var full_history_enabled:bool = true
var full_history_length:int = 50

var text_read_history_enabled:bool = true

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
		pass
		
	if text_read_history_enabled:
		pass
	
	pass
