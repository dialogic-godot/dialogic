tool
extends DialogicEvent
class_name MyCustomEvent

func _init() -> void:
	event_name = "Custom Event Test"


func _execute() -> void:
	print("Hello")
