class_name DialogicAnimation
extends Node

## Class that can be used to animate portraits. Can be extended to create animations. 

signal finished_once
signal finished

## Set at runtime, will be the node to animate.
var node :Node
## Set at runtime, will be the length of the animation.
var time : float
## Set at runtime, will be the position at which to end the animation.
var end_position : Vector2
## Set at runtime. The position the node started at.
var orig_pos : Vector2

## Used to repeate the animation for a number of times.
var repeats : int


func _ready():
	connect('finished_once', finished_one_loop)


## To be overridden. Do the actual animating/tweening in here. 
## Use the properties [node], [time], [end_position], [orig_pos].
func animate():
	pass


func finished_one_loop():
	repeats -= 1
	if repeats > 0:
		animate()
	elif repeats == 0:
		emit_signal("finished")


func pause():
	if node:
		node.process_mode = Node.PROCESS_MODE_DISABLED


func resume():
	if node:
		node.process_mode = Node.PROCESS_MODE_INHERIT
