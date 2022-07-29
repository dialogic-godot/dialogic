extends Control

func _ready():
	get_child(0).visibility_changed.connect(visiblity_changed)

func visiblity_changed():
	visible = get_child(0).visible
