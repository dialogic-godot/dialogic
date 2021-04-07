extends Resource
class_name DialogicTimelineResource

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
