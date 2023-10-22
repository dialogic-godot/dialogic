class_name DialogicNode_Input
extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group('dialogic_input')
	gui_input.connect(_on_gui_input)

func _on_gui_input(event:InputEvent) -> void:
	if Input.is_action_pressed(ProjectSettings.get_setting('dialogic/text/input_action', 'dialogic_default_action')):
		if event is InputEventMouse:
			Dialogic.Input.handle_input()
