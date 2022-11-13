class_name DialogicNode_PortraitPosition
extends Marker2D

## Used to identify positions in the [DialogicCharacterEvent].
@export var position_index = 0


func _ready() -> void:
	add_to_group('dialogic_portrait_position')
