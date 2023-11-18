class_name DialogicNode_BackgroundHolder
extends ColorRect


func _ready():
	add_to_group('dialogic_background_holders')
	if material == null:
		material = ShaderMaterial.new()
		material.shader = preload("res://addons/dialogic/Modules/Background/default_background_transition.gdshader")
