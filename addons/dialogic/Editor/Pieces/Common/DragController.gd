tool
extends Control

var moving

func _ready():
	get_parent().connect("gui_input", self, '_on_gui_input')


func _process(delta):
	if moving:
		var current_position = get_global_mouse_position()
		var movement_offset = 15
		var height = get_parent().get_node("PanelContainer").rect_size.y + movement_offset
		var node_position = get_parent().rect_global_position.y
		if current_position.y < node_position - movement_offset:
			get_parent().get_node("PanelContainer/VBoxContainer/Header/OptionButton")._on_OptionSelected(0)
		if current_position.y > node_position + height:
			get_parent().get_node("PanelContainer/VBoxContainer/Header/OptionButton")._on_OptionSelected(1)


func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == 1:
		if moving:
			moving = false
		else:
			moving = true
