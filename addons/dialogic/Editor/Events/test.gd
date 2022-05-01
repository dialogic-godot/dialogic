tool
extends DialogicEvent
class_name MyCustomEvent

func _init() -> void:
	event_name = "Custom Event"


func _execute() -> void:
	print("Hello")
