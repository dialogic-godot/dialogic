extends Resource
class_name DialogicEventResource

signal event_started(event_resource)
signal event_finished

# Should be remade with caller:DialogNode when 4.0 comes out
func excecute(caller:Control) -> void:
	emit_signal("event_started", self)
