tool
extends PanelContainer

onready var nodes = {
	'title': $VBoxContainer/Title,
	'body': $VBoxContainer/Content,
	'extra': $VBoxContainer/Extra,
}

var in_theme_editor = false
var margin = 10


func _ready():
	rect_size.y = 0


func _process(_delta):
	if Engine.is_editor_hint() == false or in_theme_editor == true:
		if visible:
			if get_global_mouse_position().x < get_viewport().size.x * 0.5:
				rect_global_position = get_global_mouse_position() - Vector2(0, rect_size.y + (margin * 2))
			else:
				rect_global_position = get_global_mouse_position() - rect_size - Vector2(0, (margin * 2))
			rect_size.y = 0
			$ColorRect.margin_top = - margin
			$ColorRect.margin_left = - margin * 1.25
			$ColorRect.margin_right = rect_size.x + margin * 1.25
			$ColorRect.margin_bottom = rect_size.y + margin


func load_preview(info):
	nodes['title'].visible = false
	nodes['body'].visible = false
	nodes['extra'].visible = false
	
	if info['title'] != '':
		nodes['title'].text = info['title']
		nodes['title'].visible = true
		nodes['title'].set('custom_colors/default_color', get_parent().settings['glossary_color'])
	
	if info['body'] != '':
		nodes['body'].text = info['body']
		nodes['body'].visible = true
	
	if info['extra'] != '':
		nodes['extra'].text = info['extra']
		nodes['extra'].visible = true
