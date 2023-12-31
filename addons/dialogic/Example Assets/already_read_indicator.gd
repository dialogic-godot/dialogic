extends Control

func _ready():
	if DialogicUtil.autoload().has_subsystem('History'):
		DialogicUtil.autoload().History.already_read_event_reached.connect(_on_already_read_event)
		DialogicUtil.autoload().History.not_read_event_reached.connect(_on_not_read_event)

func _on_already_read_event() -> void:
	show()

func _on_not_read_event() -> void:
	hide()
