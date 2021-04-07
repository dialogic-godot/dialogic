tool
extends DialogicEventResource
class_name DialogicCharacterLeaveEvent
export(Resource) var character = null

func excecute(caller) -> void:
	.excecute(caller)
	
	if not character:
		for portrait in caller.PortraitsNode.get_children():
			portrait.queue_free()
	
	finish()
