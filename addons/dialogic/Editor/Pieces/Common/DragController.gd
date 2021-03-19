tool
extends Control

var moving
var hover = false

func _ready():
	get_parent().connect("gui_input", self, '_on_gui_input')
	get_parent().connect("mouse_entered", self, '_on_mouse_entered')
	get_parent().connect("mouse_exited", self, '_on_mouse_exited')

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
	
	# TODO: I have to figure out a way to modify only an instance's theme. 
	# This code modifies the custom theme of all the same kind of scenes.
	
	#if hover:
	#	get_parent().get_node("PanelContainer").self_modulate = Color("#dd42ff")
	#	var panel = get_parent().get_node("PanelContainer").get('custom_styles/panel')
	#	panel.set('border_color', '#ffffff')
	#else:
	#	get_parent().get_node("PanelContainer").self_modulate = Color("#ffffff")
	#	var panel = get_parent().get_node("PanelContainer").get('custom_styles/panel')
	#	panel.set('border_color', '#202020')


func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == 1:
		if moving:
			moving = false
		else:
			moving = true


func _on_mouse_entered():
	hover = true


func _on_mouse_exited():
	hover = false
