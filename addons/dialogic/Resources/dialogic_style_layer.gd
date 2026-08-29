@tool
class_name DialogicStyleLayer
extends Resource

## Reference to the scene that this layer uses.
@export var scene: PackedScene = null
## Dictionary of all the overrides for this layer.
@export var overrides := {}
## If true, this layer doesn't instance a scene but is already a child of the styles root layer
## it will only carry the overrides that should be applied to that node.
@export var child_of_base := false


func _init(scene_path:Variant=null, scene_overrides:Dictionary={}):
	if scene_path is PackedScene:
		scene = scene_path
	elif scene_path is String and ResourceLoader.exists(scene_path):
		scene = load(scene_path)
	overrides = scene_overrides


func _to_string() -> String:
	if scene:
		return "<Layer:" + scene.resource_path + " {" + str(len(overrides)) + " overrides}>"
	elif child_of_base:
		return "<Layer: Child of root layer {" + str(len(overrides)) + " overrides}>"
	else:
		return "<Layer:no-scene>"


## Attempt updating overrides from alpha 20 or earlier.
func update_to_alpha21() -> void:
	if overrides.is_empty() or ":" in overrides.keys()[0]:
		return
	var new_overrides := {}
	for i in overrides:
		if typeof(overrides[i]) == TYPE_STRING:
			new_overrides[".:"+i] = str_to_var(overrides[i])
		else:
			new_overrides[".:"+i] = overrides[i]
	overrides = new_overrides
	print("[Dialogic] Updating style layer overrides: ", self)
