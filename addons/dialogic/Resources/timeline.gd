@tool
extends Resource
class_name DialogicTimeline

@export var dialogic_version:String


var events:Array = []:
	get:
		return events
	set(value):
		emit_changed()
		notify_property_list_changed()
		events = value
		
var events_processed:bool = false


func set_events(_events:Array) -> void:
	events = _events
	emit_changed()
	notify_property_list_changed()


func add_event(event, at_position:int =-1) -> void:
	var idx : int = at_position if at_position > -1 else events.size()
	events.insert(idx, event)
	emit_changed()
	notify_property_list_changed()


func erase_event(event) -> void:
	events.erase(event)
	emit_changed()
	notify_property_list_changed()


func remove_event(position:int) -> void:
	events.erase(position)
	emit_changed()
	notify_property_list_changed()


func get_event(index):
	if index >= len(events):
		return null
	return events[index]


func get_events() -> Array:
	return events.duplicate()


func _set(property, value):
	if str(property).begins_with("event/"):
		var event_idx:int = str(property).split("/", true, 2)[1].to_int()
		if event_idx < events.size():
			events[event_idx] = value
		else:
			events.insert(event_idx, value)
		
		emit_changed()
		notify_property_list_changed()
	
	if property == "events":
		set_events(value)
		return true
	
	return false

func _get(property):
	if str(property).begins_with("event/"):
		var event_idx:int = str(property).split("/", true, 2)[1].to_int()
		if event_idx < len(events):
			return events[event_idx]
			return true

func _init() -> void:
	events = []
	resource_name = get_class()


func _to_string() -> String:
	return "[{class}:{file}]".format({"class":get_class(), "file":resource_path})


func get_class() -> String: return "Timeline"


func _get_property_list() -> Array:
	var p : Array = []
	var usage = PROPERTY_USAGE_SCRIPT_VARIABLE
	usage |= PROPERTY_USAGE_NO_EDITOR
	usage |= PROPERTY_USAGE_EDITOR # Comment this line to hide events from editor
	if events != null:
		for event_idx in events.size():
			p.append(
				{
					"name":"event/{idx}".format({"idx":event_idx}),
					"type":TYPE_OBJECT,
					"usage":PROPERTY_USAGE_DEFAULT|PROPERTY_USAGE_SCRIPT_VARIABLE
				}
			)
	return p
