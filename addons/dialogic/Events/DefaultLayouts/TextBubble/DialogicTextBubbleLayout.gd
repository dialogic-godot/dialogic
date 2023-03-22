extends Control

enum SizingModes {AdjustAlways, AdjustOnStart, Fixed}
@export var sizing_mode: SizingModes = SizingModes.AdjustAlways

@export var max_width :float= 0
@export var max_lines = 10

func _ready():
	if max_width <= 0:
		max_width = get_viewport().size.x/2

func _on_DialogText_continued_revealing_text(new_character = ""):
	if sizing_mode == SizingModes.AdjustAlways:
		var font = $DialogText.get_theme_font("normal_font")
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
		if sizing_mode == SizingModes.AdjustAlways:
			custom_minimum_size.x = min(max_width, longest_line_len)
			# a margin has to be added vertically as well because of the stylebox
			custom_minimum_size.y = line_height*min(lines, max_lines)+20
			# Enable Scroll bar when more then max lines
			$DialogText.scroll_active = lines > max_lines

		elif lines*line_height+40 > $DialogText.size.y:
			$DialogText.scroll_active = true
	
	if $DialogText.scroll_active:
#		$DialogText.get_v_scroll_bar().position.x = $DialogText.size.x-20
#		$DialogText.get_v_scroll_bar().margin_right = -20
		$DialogText.scroll_to_line($DialogText.get_line_count())


func _on_dialog_text_started_revealing_text():
	if sizing_mode == SizingModes.AdjustOnStart:
		var font = $DialogText.get_theme_font("normal_font")
		var line_height = font.get_height()
		var longest_line_len = 0
		var lines = 0
		for line in $DialogText.text.split("\n"):
			longest_line_len = font.get_string_size(line).x if font.get_string_size(line).x > longest_line_len else longest_line_len
			if font.get_string_size(line).x > max_width-60:
				lines += ceil(font.get_string_size(line).x/(max_width-60))-1
			lines += 1

		# because there is a margin and a number inside the stylebox (especially to the left) this needs to be added 
		longest_line_len += 100
		custom_minimum_size.x = min(max_width, longest_line_len)
		# a margin has to be added vertically as well because of the stylebox
		custom_minimum_size.y = line_height*min(lines, max_lines)
		if Dialogic.Choices.is_question(Dialogic.current_event_idx):
			custom_minimum_size.y += 80
			$DialogText.offset_bottom = -25
		
		# Enable Scroll bar when more then max lines
		$DialogText.scroll_active = lines > max_lines

		if lines*line_height+40 > $DialogText.size.y:
			$DialogText.scroll_active = true
	else:
		$DialogText.offset_bottom = -7


func _on_dialog_text_finished_revealing_text():
	if sizing_mode == SizingModes.AdjustAlways:
		if Dialogic.Choices.is_question(Dialogic.current_event_idx):
			$DialogText.offset_bottom = -25
		else:
			$DialogText.offset_bottom = -7
