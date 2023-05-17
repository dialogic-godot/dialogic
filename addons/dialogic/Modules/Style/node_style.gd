class_name DialogicNode_Style
extends Control

## Control node that is hidden and shown based on the current dialogic style. 

## The style this node belongs to.
@export var style_name: String = 'Default'


func _ready():
	if style_name.is_empty():
		style_name = name
	add_to_group('dialogic_styles')
