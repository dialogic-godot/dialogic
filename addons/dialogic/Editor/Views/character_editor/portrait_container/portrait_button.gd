tool
extends Button


func _pressed() -> void:
	emit_signal("pressed", self)
