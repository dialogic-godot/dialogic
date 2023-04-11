extends Node
class_name DialogicSubsystem

var dialogic = null

# To be overriden by sub-classes
# Fill in everything that should be cleared (for example before loading a different state)
func clear_game_state():
	pass

# To be overriden by sub-classes
# Fill in everything that should be loaded using the dialogic_game_handler.current_state_info
# This is called when a save is loaded
func load_game_state():
	pass

# To be overriden by sub-classes
func pause() -> void:
	pass

# To be overriden by sub-classes
func resume() -> void:
	pass
