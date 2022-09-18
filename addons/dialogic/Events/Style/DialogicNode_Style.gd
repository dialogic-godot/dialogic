extends Control

class_name DialogicNode_Style


@export var style_name:String = 'Default'

func _ready():
	if style_name.is_empty():
		style_name = name
	add_to_group('dialogic_styles')
