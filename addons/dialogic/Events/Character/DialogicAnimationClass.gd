extends Node
class_name DialogicAnimation

var node :Node
var time : float
var end_position : Vector2

var repeats : int
var orig_pos : Vector2

signal finished_once
signal finished

func _ready():
	connect('finished_once', finished_one_loop)

# to be overridden
func animate():
	pass

func finished_one_loop():
	repeats -= 1
	if repeats > 0:
		animate()
	elif repeats == 0:
		emit_signal("finished")
	
func pause():
	process_mode = Node.PROCESS_MODE_DISABLED

func resume():
	process_mode = Node.PROCESS_MODE_INHERIT
