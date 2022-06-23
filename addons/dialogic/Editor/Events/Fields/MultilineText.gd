tool
extends Control

var property_name : String
signal value_changed

func _ready():
	find_parent('TimelineArea').connect('resized', self, 'change_size')
	$TextEdit.connect("text_changed", self,  'text_changed')

func text_changed(value = ""):
	change_size()
	emit_signal("value_changed", property_name, $TextEdit.text)

func set_left_text(value):
	$LeftText.text = str(value)

func set_right_text(value):
	$RightText.text = str(value)

func set_value(value):
	$TextEdit.text = str(value)


func change_size():
	print('resize')
	var longest_line = 0
	var font = get_font("normal_font")
	var lines = 0
	var max_width = get_max_width()
	var line_height = font.get_height()+4
	for line in $TextEdit.text.split("\n"):
		longest_line = font.get_string_size(line).x if font.get_string_size(line).x > longest_line else longest_line
		if font.get_string_size(line).x+50 > max_width:
			lines += ceil(get_font("normal_font").get_string_size(line).x/(max_width))
		lines += 1
	longest_line += 50
	print(longest_line)
	print(get_parent().rect_size.x)
	$TextEdit.rect_min_size.x = min(max_width, longest_line)
	$TextEdit.rect_min_size.y = line_height*lines+20

func get_max_width():
	return find_parent('View').get_node('ScrollContainer').rect_global_position.x- $TextEdit.rect_global_position.x -50
