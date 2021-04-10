tool
class_name DialogicTimelineResource
extends Resource

export(Resource) var events = ResourceArray.new() setget _set_events

var current_event = 0

func start(caller):
	var _err
	var _events = (events.get_resources() as DialogicEventResource)
	if not _events[current_event].is_connected("event_started", caller, "_on_event_start"):
		_err = _events[current_event].connect("event_started", caller, "_on_event_start")
		if _err != OK:
			print_debug(_err)
	if not _events[current_event].is_connected("event_finished", caller, "_on_event_finished"):
		_err = _events[current_event].connect("event_finished", caller, "_on_event_finished")
		if _err != OK:
			print_debug(_err)
	
	_events[current_event].excecute(caller)

func go_to_next_event(caller):
	current_event += 1
	current_event = clamp(current_event, 0, events.size())
	if current_event == events.get_resources().size():
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

func _set_events(value) -> void:
	events = value
	if not value:
		events = ResourceArray.new()
	emit_signal("changed")
