@tool
extends Resource
class_name DialogicTimeline


var events:Array = []:
	get:
		return events
	set(value):
		emit_changed()
		notify_property_list_changed()
		events = value
		
var events_processed:bool = false


func get_event(index):
	if index >= len(events):
		return null
	return events[index]


func _set(property, value):
	if str(property).begins_with("event/"):
		var event_idx:int = str(property).split("/", true, 2)[1].to_int()
		if event_idx < events.size():
			events[event_idx] = value
		else:
			events.insert(event_idx, value)
		
		emit_changed()
		notify_property_list_changed()

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
	return "[DialogicTimeline:{file}]".format({"file":resource_path})


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
