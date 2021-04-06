extends Resource
class_name DialogicEventResource

signal event_started(event_resource)
signal event_finished(event_resource)

# Should be remade with caller:DialogNode when 4.0 comes out

#waring-ignore-all:unused_argument
func excecute(caller:Control) -> void:
	emit_signal("event_started", self)


func finish():
	emit_signal("event_finished", self)
