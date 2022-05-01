tool
extends Resource
class_name DialogicTimeline

export (String) var dialogic_version

#export(Array, Resource) var events : Array

# -----------------------------------------
# Emilio:
# Stuff I yet don't understand made by Dex:
# -----------------------------------------

# This file is part of EventSystem, distributed under MIT license
# and modified to work with Dialogic.
# You can see the license of this file here
# https://github.com/AnidemDex/Godot-EventSystem/blob/main/LICENSE

var _events:Array = [] setget set_events


func set_events(events:Array) -> void:
	_events = events
	emit_changed()
	property_list_changed_notify()


func add_event(event, at_position=-1) -> void:
	var idx = at_position if at_position > -1 else _events.size()
	_events.insert(idx, event)
	emit_changed()
	property_list_changed_notify()


func erase_event(event) -> void:
	_events.erase(event)
	emit_changed()
	property_list_changed_notify()


func remove_event(position:int) -> void:
	_events.remove(position)
	emit_changed()
	property_list_changed_notify()


func get_events() -> Array:
	return _events.duplicate()


func _set(property:String, value) -> bool:
	if property.begins_with("event/"):
		var event_idx:int = int(property.split("/", true, 2)[1])
		if event_idx < _events.size():
			_events[event_idx] = value
		else:
			_events.insert(event_idx, value)
		
		emit_changed()
		property_list_changed_notify()
	
	if property == "events":
		set_events(value)
		return true
	
	return false


func _get(property:String):
	if property.begins_with("event/"):
		var event_idx:int = int(property.split("/", true, 2)[1])
		if event_idx < _events.size():
			return _events[event_idx]
	
	if property == "events":
		return get_events()


func _init() -> void:
	_events = []
	resource_name = get_class()


func _to_string() -> String:
	return "[{class}:{id}]".format({"class":get_class(), "id":get_instance_id()})


func get_class() -> String: return "Timeline"


func _get_property_list() -> Array:
	var p = []
	var usage = PROPERTY_USAGE_SCRIPT_VARIABLE
	usage |= PROPERTY_USAGE_NOEDITOR
	usage |= PROPERTY_USAGE_EDITOR # Comment this line to hide events from editor
	for event_idx in _events.size():
		p.append(
			{
				"name":"event/{idx}".format({"idx":event_idx}),
				"type":TYPE_OBJECT,
				"usage":PROPERTY_USAGE_DEFAULT|PROPERTY_USAGE_SCRIPT_VARIABLE
			}
		)
	return p
