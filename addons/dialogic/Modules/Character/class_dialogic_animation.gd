class_name DialogicAnimation
extends Node

## Class that can be used to animate portraits. Can be extended to create animations.

signal finished_once
signal finished

## Set at runtime, will be the node to animate.
var node: Node

## Set at runtime, will be the length of the animation.
var time: float

## Set at runtime, will be the position at which to end the animation.
var end_position: Vector2

## Set at runtime. The position the node started at.
var orig_pos: Vector2

## Used to repeate the animation for a number of times.
var repeats: int

## If `true`, the animation will be reversed.
## This must be implemented by each animation or it will have no effect.
var is_reversed: bool = false


func _ready() -> void:
	finished_once.connect(finished_one_loop)


## To be overridden. Do the actual animating/tweening in here.
## Use the properties [member node], [member time], [member end_position], [member orig_pos].
func animate() -> void:
	pass


## This method controls whether to repeat the animation or not.
## Animations must call this once they finished an animation.
func finished_one_loop() -> void:
	repeats -= 1

	if repeats > 0:
		animate()

	else:
		finished.emit()


func pause() -> void:
	if node:
		node.process_mode = Node.PROCESS_MODE_DISABLED


func resume() -> void:
	if node:
		node.process_mode = Node.PROCESS_MODE_INHERIT


## If the animation wants to change the modulation, this method
## will return the property to change.
##
## The [class CanvasGroup] can use `self_modulate` instead of `modulate`
## to uniformly change the modulation of all children without additively
## overlaying the modulations.
func get_modulation_property() -> String:
	if node is CanvasGroup:
		return "self_modulate"
	else:
		return "modulate"
