extends Control

func _ready():
	get_child(0).connect('visibility_changed', self, 'visiblity_changed')

func visiblity_changed():
	visible = get_child(0).visible
