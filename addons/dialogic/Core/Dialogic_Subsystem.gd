class_name DialogicSubsystem
extends Node

var dialogic: DialogicGameHandler = null

enum LoadFlags {FULL_LOAD, ONLY_DNODES}

# To be overriden by sub-classes
# Called once after every subsystem has been added to the tree
func post_install() -> void:
	pass


# To be overriden by sub-classes
# Fill in everything that should be cleared (for example before loading a different state)
func clear_game_state(_clear_flag:=DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	pass


# To be overriden by sub-classes
# Fill in everything that should be loaded using the dialogic_game_handler.current_state_info
# This is called when a save is loaded
func load_game_state(_load_flag:=LoadFlags.FULL_LOAD) -> void:
	pass


# To be overriden by sub-classes
# Fill in everything that should be saved into the dialogic_game_handler.current_state_info
# This is called when a save is saved
func save_game_state() -> void:
	pass


# To be overriden by sub-classes
func pause() -> void:
	pass


# To be overriden by sub-classes
func resume() -> void:
	pass
