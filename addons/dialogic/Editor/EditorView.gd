tool
extends Control

func _ready():
	var main_panel = $VBoxContainer
	var separation = get_constant("separation", "BoxContainer") - 1
	main_panel.margin_top = separation
	main_panel.margin_left = separation
	main_panel.margin_right = separation * -1
	main_panel.margin_bottom = separation * -1


func edit_timeline(object):
	$VBoxContainer/Toolbar/Label.text = object.resource_path
	$VBoxContainer/TimelineEditor.load_timeline(object)
