extends Control


## The timeline to load when starting the scene
export(String, "TimelineDropdown") var timeline: String
export(bool) var add_canvas = true
export(bool) var reset_saves = true
export(bool) var debug_mode = false

func _ready():
	var d = Dialogic.start(timeline, '', "res://addons/dialogic/Nodes/DialogNode.tscn",  debug_mode, add_canvas)
	get_parent().call_deferred('add_child', d)
	queue_free()
