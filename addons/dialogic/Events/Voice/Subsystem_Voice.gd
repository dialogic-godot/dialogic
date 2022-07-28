extends DialogicSubsystem

func isVoiced(index:int) -> bool:
	if dialogic.current_timeline_events[index] is DialogicTextEvent:
		if dialogic.current_timeline_events[index-1] is DialogicVoiceEvent:
			return true
	return false

func playVoiceRegion(index:int):
	pass#TODO
	
func setFile(path:String):
	pass#TODO
	
func setVolume(value:float):
	pass#TODO

func setRegions(value:Array):
	pass#TODO

func setBus(value:String):
	pass#TODO
	

# To be overriden by sub-classes
# Fill in everything that should be cleared (for example before loading a different state)
func clear_game_state():
	pass

# To be overriden by sub-classes
# Fill in everything that should be loaded using the dialogic_game_handler.current_state_info
# This is called when a save is loaded
func load_game_state():
	pass
	
