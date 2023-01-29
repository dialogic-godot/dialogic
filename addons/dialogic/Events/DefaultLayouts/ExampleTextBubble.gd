extends Control

enum sizing_modes {ADJUST_TO_TEXT_LENGTH, KEEP_FIXED}
@export_enum(sizing_modes) var sizing_mode:int = sizing_modes.ADJUST_TO_TEXT_LENGTH

@onready var max_width = get_viewport().size.x/2
@onready var max_lines = 5

func _on_DialogText_continued_revealing_text(new_character = ""):
	var font = $DialogText.get_font("normal_font")
	var line_height = font.get_height()
	var longest_line_len = 0
	var lines = 0
	for line in $DialogText.text.substr(0, $DialogText.visible_characters).split("\n"):
		longest_line_len = font.get_string_size(line).x if font.get_string_size(line).x > longest_line_len else longest_line_len
		if font.get_string_size(line).x > max_width-60:
			lines += ceil(font.get_string_size(line).x/(max_width-60))-1
		lines += 1
	
	# because there is a margin and a number inside the stylebox (especially to the left) this needs to be added 
	longest_line_len += 100
	if sizing_mode == sizing_modes.ADJUST_TO_TEXT_LENGTH:
		custom_minimum_size.x = min(max_width, longest_line_len)
		# a margin has to be added vertically as well because of the stylebox
		custom_minimum_size.y = line_height*min(lines, max_lines)+40
		# Enable Scroll bar when more then max lines
		$DialogText.scroll_active = lines > max_lines
	
	elif lines*line_height+40 > $DialogText.size.y:
		$DialogText.scroll_active = true
	if $DialogText.scroll_active:
		$DialogText.get_v_scroll().rect_position.x = $DialogText.size.x-20
		$DialogText.get_v_scroll().margin_right = -20
		$DialogText.scroll_to_line(lines-max_lines)
