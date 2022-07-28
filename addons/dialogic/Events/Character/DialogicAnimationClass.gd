extends Node
class_name DialogicAnimation

var node
var time
var end_position

var repeats
var orig_pos

signal finished_once
signal finished

func _ready():
	connect('finished_once', self.finished_one_loop)

# to be overridden
func animate():
	pass

func finished_one_loop():
	repeats -= 1
	if repeats > 0:
		animate()
	elif repeats == 0:
		emit_signal("finished")
	
