class_name DialogicSubsystem
extends Node

var dialogic: DialogicGameHandler = null

enum LoadFlags {FULL_LOAD, ONLY_DNODES}


# To be overriden by sub-classes
# Called once after every subsystem has been added to the tree
func _post_install() -> void:
	pass


# To be overriden by sub-classes
# Fill in everything that should be cleared (for example before loading a different state)
func _clear_state(_clear_flag:=DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	pass


# To be overriden by sub-classes
func _pause() -> void:
	pass


# To be overriden by sub-classes
func _resume() -> void:
	pass


func load_state(load_flag:=LoadFlags.FULL_LOAD) -> void:
	#unpack_state(state)
	_load_state(load_flag)


func _load_state(_load_flag:=LoadFlags.FULL_LOAD) -> void:
	pass


func get_state() -> Dictionary:
	#save_game_state()
	return pack_state()


func pack_state() -> Dictionary:
	var info := {}
	for i in self.script.get_script_property_list():
		if i.usage & PROPERTY_USAGE_EDITOR == PROPERTY_USAGE_EDITOR:
			info[i.name] = self.get(i.name)
	return info


func unpack_state(info:Dictionary) -> void:
	for i in self.script.get_script_property_list():
		if i.usage & PROPERTY_USAGE_EDITOR == PROPERTY_USAGE_EDITOR:
			if i.name in info:
				self.set(i.name, info[i.name])
