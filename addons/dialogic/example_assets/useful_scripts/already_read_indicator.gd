extends Control

func _ready() -> void:
	if DialogicUtil.autoload().has_subsystem('History'):
		DialogicUtil.autoload().History.visited_event.connect(_on_visited_event)
		DialogicUtil.autoload().History.unvisited_event.connect(_on_not_read_event)

func _on_visited_event() -> void:
	show()

func _on_not_read_event() -> void:
	hide()
