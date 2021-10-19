extends Control


## The timeline to load when starting the scene
export(String, "TimelineDropdown") var timeline: String
export(bool) var add_canvas = true
export(bool) var reset_saves = true

func _ready():
	var d = Dialogic.start(timeline, '', "res://addons/dialogic/Nodes/DialogNode.tscn", add_canvas)
	get_parent().call_deferred('add_child', d)
	queue_free()
