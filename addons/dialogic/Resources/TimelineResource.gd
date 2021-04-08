tool
class_name DialogicTimelineResource
extends Resource

export(Array, Resource) var events:Array = []

var current_event = 0

func start(caller):
	var _err
	if not (events[current_event] as Object).is_connected("event_started", caller, "_on_event_start"):
		_err = (events[current_event] as Object).connect("event_started", caller, "_on_event_start")
		if _err != OK:
			print_debug(_err)
	if not (events[current_event] as Object).is_connected("event_finished", caller, "_on_event_finished"):
		_err = (events[current_event] as Object).connect("event_finished", caller, "_on_event_finished")
		if _err != OK:
			print_debug(_err)
	
	events[current_event].excecute(caller)

func go_to_next_event(caller):
	current_event += 1
	current_event = clamp(current_event, 0, events.size())
	if current_event == events.size():
		caller.queue_free()
	else:
		start(caller)

func get_good_name(with_name:String="") -> String:
	var _good_name = with_name
	
	if not _good_name:
		_good_name = resource_name if resource_name else resource_path
	else:
		if _good_name.begins_with("res://"):
			_good_name = _good_name.replace("res://", "")
		if _good_name.ends_with(".tres"):
			_good_name = _good_name.replace(".tres", "")
		_good_name = _good_name.capitalize()
	
	return _good_name
