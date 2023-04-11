extends Control

func _ready():
	if Dialogic.has_subsystem('History'):
		Dialogic.History.already_read_event_reached.connect(_on_already_read_event)
		Dialogic.History.not_read_event_reached.connect(_on_not_read_event)

func _on_already_read_event() -> void:
	show()

func _on_not_read_event() -> void:
	hide()
