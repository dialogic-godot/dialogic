class_name DialogicSubsystem
extends Node

## A (mostly) standalone system inside Dialogic.
##
## Subclasses registered via a [class DialogicIndexer] will be instanced as children of the [class DialogicGameHandler].[br]
## These systems should provide easy access to methods and settings regarding their logic.[br]
## By overwriting the classes various methods, they should handle saving and loading of the system.[br]
## Exported variables on a subsystem will be considered relevant for the save-state, so on save they will be packed and
## unpacked on load before [method _load_state] is called.
## Additional state (e.g. from nodes in the scene, can be collected in [method _pack_extra_state].

## A reference to the [class DialogicGameHandler] this subsystem instance belongs to.
## Currently only the Dialogic autoload instance of DialogicGameHandler is supported.
var dialogic: DialogicGameHandler = null

enum LoadFlags {FULL_LOAD, ONLY_DNODES}


## Called once after every subsystem has been added to the tree.
## To be overriden by sub-classes.
func _post_install() -> void:
	pass


## Reset the subsystem and clear all effects it has had on the scene tree.
## Called on DialogicGameHandler ready, clear and before loading a different state.
## To be overriden by sub-classes.
func _clear_state(_clear_flag:=DialogicGameHandler.ClearFlags.FULL_CLEAR) -> void:
	pass


## Called when `DialogicGameHandler.paused` changes to `true`. Pause all systems.
## To be overriden by sub-classes.
func _pause() -> void:
	pass


## Called when `DialogicGameHandler.paused` changes to `false`. Resume all paused systems.
## To be overriden by sub-classes.
func _resume() -> void:
	pass


## Called when a state is loaded by the DialogicGameHandler.
## Calls [method _load_state].
## It should usually not be necessary to access this directly.
func load_state(load_flag:=LoadFlags.FULL_LOAD) -> void:
	_load_state(load_flag)


## Make sure to recreate the state from the exported state variables (have been unpacked before this) and the "extra-state" which you can access with [method get_extra_state].
## To be overriden by sub-classes.
func _load_state(_load_flag:=LoadFlags.FULL_LOAD) -> void:
	pass


## Called by DialogGameHandler to get the current state of the subsystem.
## Combines the result of [method pack_exported_state] and [method _get_extra_state].
func get_state() -> Dictionary:
	return pack_exported_state().merged(pack_extra_state())


## Used by [method get_state]. Calls [method _pack_extra_state].
func pack_extra_state() -> Dictionary:
	return _pack_extra_state()


## To be overriden by sub-classes.
## Return a dictionary with all the info you want to save (that isn't already represented by the exported state variables).
## This is especially useful for saving the state of elements in the scene tree.
## To get this state after a later load, use [method get_extra_state].
func _pack_extra_state() -> Dictionary:
	return {}


## If called after a load, this will return the extra state dictionary that was packed by [method _pack_extra_state].
func get_extra_state() -> Dictionary:
	return get_meta("extra_state", {})


## Packs all the exported variables into a dictionary.
func pack_exported_state() -> Dictionary:
	var info := {}
	for i in self.script.get_script_property_list():
		if i.usage & PROPERTY_USAGE_EDITOR == PROPERTY_USAGE_EDITOR:
			info[i.name] = self.get(i.name)
	return info


## Unpacks the values from the given info dictionary into the exported variables.
func unpack_state(info:Dictionary) -> void:
	var leftovers := info.duplicate()
	for i in self.script.get_script_property_list():
		if i.usage & PROPERTY_USAGE_EDITOR == PROPERTY_USAGE_EDITOR:
			if i.name in info:
				self.set(i.name, info[i.name])
				leftovers.erase(i.name)
	set_meta("extra_state", leftovers)
