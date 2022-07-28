@tool
extends Control

var property_name : String
signal value_changed

func _ready():
	find_parent('TimelineArea').resized.connect(change_size)
	$TextEdit.text_changed.connect(text_changed)
	change_size()

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
	# the distance between the sidebar of the timeline editor and the TextEdit box.
	var max_width = find_parent('View').get_node('ScrollContainer').global_position.x- $TextEdit.global_position.x 
	# adding a margin
	max_width -= 50 * DialogicUtil.get_editor_scale()
	
	var font = get_theme_font("normal_font")
	var line_height = font.get_height()+4
	
	var longest_line_len = 0
	var lines = 0
	for line in $TextEdit.text.split("\n"):
		longest_line_len = font.get_string_size(line).x if font.get_string_size(line).x > longest_line_len else longest_line_len
		if font.get_string_size(line).x+50 > max_width:
			lines += ceil(get_theme_font("normal_font").get_string_size(line).x/(max_width))
		lines += 1
	
	# because there is a margin and a number inside the stylebox (especially to the left) this needs to be added 
	longest_line_len += 50 * DialogicUtil.get_editor_scale()
	$TextEdit.custom_minimum_size.x = min(max_width, longest_line_len)
	# a margin has to be added vertically as well because of the stylebox
	$TextEdit.custom_minimum_size.y = line_height*lines + (20 * DialogicUtil.get_editor_scale())
