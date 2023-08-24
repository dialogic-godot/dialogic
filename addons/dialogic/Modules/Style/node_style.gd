class_name DialogicNode_StyleLayer
extends Control

## Control node that is hidden and shown based on the current dialogic style. 

## The name this layer listens to
@export var layer_name: String = 'Default'


func _ready():
	if layer_name.is_empty():
		layer_name = name
	add_to_group('dialogic_style_layer')
