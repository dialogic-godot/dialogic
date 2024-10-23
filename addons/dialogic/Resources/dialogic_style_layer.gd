@tool
class_name DialogicStyleLayer
extends Resource

@export var scene: PackedScene = null
@export var overrides := {}


func _init(scene_path:Variant=null, scene_overrides:Dictionary={}):
	if scene_path is PackedScene:
		scene = scene_path
	elif scene_path is String and ResourceLoader.exists(scene_path):
		scene = load(scene_path)
	overrides = scene_overrides
