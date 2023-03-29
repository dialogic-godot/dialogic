extends Control

func _ready():
	get_child(0).visibility_changed.connect(_on_child_visibility_changed)
	_on_child_visibility_changed()

func _on_child_visibility_changed():
	visible = get_child(0).visible
