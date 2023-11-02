class_name DialogicNode_Input
extends Control

## A node that handles mouse input. This allows limiting mouse input to a
## specific region and avoiding conflicts with other UI elements.
## If no Input node is used, the input subsystem will handle mouse input instead.

func _ready():
	add_to_group('dialogic_input')
	gui_input.connect(_on_gui_input)

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed(ProjectSettings.get_setting('dialogic/text/input_action', 'dialogic_default_action')):
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_gui_input(event:InputEvent) -> void:
	if Input.is_action_just_pressed(ProjectSettings.get_setting('dialogic/text/input_action', 'dialogic_default_action')):
		if event is InputEventMouseButton and event.pressed:
			Dialogic.Input.handle_input()
