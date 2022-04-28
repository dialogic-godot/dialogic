tool
extends Control

func _ready():
	add_margin($TimelineEditor, get_constant("separation", "BoxContainer") - 1)


func edit_timeline(object):
	$TimelineEditor.load_timeline(object)


func add_margin(node, separation):
	node.margin_top = separation
	node.margin_left = separation
	node.margin_right = separation * -1
	node.margin_bottom = separation * -1
