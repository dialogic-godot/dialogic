tool
extends Container

func _ready():
	var main_panel = self
	var separation = get_constant("separation", "BoxContainer") - 1
	main_panel.margin_top = separation
	main_panel.margin_left = separation
	main_panel.margin_right = separation * -1
	main_panel.margin_bottom = separation * -1


func edit_timeline(object):
	$TimelineEditor.load_timeline(object)
