tool
extends Resource
class_name DialogicEvent

export (String) var id
export (String) var name
export (Texture) var icon
export (Color) var color

# Hopefully we can replace this with a cleaner system
# maybe even generate them based on some markup? who knows, it is free to dream
export(Array, Resource) var header : Array
export(Array, Resource) var body : Array


export (int, 'Main', 'Logic', 'Timeline', 'Audio/Visual', 'Godot', 'Other') var category

export (String) var help_page_path

export (bool) var expand_by_default : bool = true
export (bool) var needs_indentation : bool = false
export (bool) var display_name : bool = true

export (int) var sorting_index : int

# -----------------------------------------
# Emilio:
# Stuff I yet don't understand made by Dex:
# -----------------------------------------

# This file is part of EventSystem, distributed under MIT license
# and modified to work with Dialogic.
# You can see the license of this file here
# https://github.com/AnidemDex/Godot-EventSystem/blob/main/LICENSE


## 
## Base class for all events.
##
## @desc: 
##    Every event relies on this class. 
##    If you want to do your own event, you should [code]extend[/code] this class.
##

## Emmited when the event starts.
## The signal is emmited with the event resource [code]event_resource[/code]
signal event_started(event_resource)

## Emmited when the event finish. 
## The signal is emmited with the event resource [code]event_resource[/code]
signal event_finished(event_resource)

##########
# Default Event Properties
##########

## Determines if the event will go to next event inmediatly or not. 
## If value is true, the next event will be executed when event ends.
export(bool) var continue_at_end:bool = true setget _set_continue


## Executes the event behaviour.
func execute() -> void:
	emit_signal("event_started", self)
	
	call_deferred("_execute")


## Ends the event behaviour.
func finish() -> void:
	emit_signal("event_finished", self)


func _execute() -> void:
	finish()


func _set_continue(value:bool) -> void:
	continue_at_end = value
	property_list_changed_notify()
	emit_changed()


func property_can_revert(property:String) -> bool:
	if property == "event_node_path":
		return true
	return false


func property_get_revert(property:String):
	if property == "event_node_path":
		return NodePath()


func _to_string() -> String:
	return "[{name}:{id}]".format({"name":name, "id":get_instance_id()})


func _hide_script_from_inspector():
	return true
