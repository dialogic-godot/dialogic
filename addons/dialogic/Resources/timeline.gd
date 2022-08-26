@tool
extends Resource
class_name DialogicTimeline

@export var dialogic_version:String


var _events:Array = []:
	get:
		return _events
	set(value):
		emit_changed()
		notify_property_list_changed()
		_events = value


func set_events(events:Array) -> void:
	_events = events
	emit_changed()
	notify_property_list_changed()


func add_event(event, at_position:int =-1) -> void:
	var idx : int = at_position if at_position > -1 else _events.size()
	_events.insert(idx, event)
	emit_changed()
	notify_property_list_changed()


func erase_event(event) -> void:
	_events.erase(event)
	emit_changed()
	notify_property_list_changed()


func remove_event(position:int) -> void:
	_events.erase(position)
	emit_changed()
	notify_property_list_changed()


func get_event(index):
	if index >= len(_events):
		return null
	return _events[index].duplicate()


func get_events() -> Array:
	return _events.duplicate()


func _set(property, value):
	if str(property).begins_with("event/"):
		var event_idx:int = str(property).split("/", true, 2)[1].to_int()
		if event_idx < _events.size():
			_events[event_idx] = value
		else:
			_events.insert(event_idx, value)
		
		emit_changed()
		notify_property_list_changed()
	
	if property == "events":
		set_events(value)
		return true
	
	return false

func _get(property):
	if str(property).begins_with("event/"):
		var event_idx:int = str(property).split("/", true, 2)[1].to_int()
		if event_idx < len(_events):
			return _events[event_idx]
			return true

func _init() -> void:
	_events = []
	resource_name = get_class()


func _to_string() -> String:
	return "[{class}:{id}]".format({"class":get_class(), "id":get_instance_id()})


func get_class() -> String: return "Timeline"


func _get_property_list() -> Array:
	var p : Array = []
	var usage = PROPERTY_USAGE_SCRIPT_VARIABLE
	usage |= PROPERTY_USAGE_NO_EDITOR
	usage |= PROPERTY_USAGE_EDITOR # Comment this line to hide events from editor
	if _events != null:
		for event_idx in _events.size():
			p.append(
				{
					"name":"event/{idx}".format({"idx":event_idx}),
					"type":TYPE_OBJECT,
					"usage":PROPERTY_USAGE_DEFAULT|PROPERTY_USAGE_SCRIPT_VARIABLE
				}
			)
	return p
