extends Position2D

export (int, 0, 100) var position_index = 0

func _ready() -> void:
	add_to_group('dialogic_portrait_position')

