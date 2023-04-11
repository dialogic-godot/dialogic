extends Container

func load_info(text:String, character:String = "", character_color:=Color(), icon:Texture= null) -> void:
	%TextBox.text = text
	if character:
		%NameLabel.text = character
		%NameLabel.add_theme_color_override('font_color', character_color)
		%NameLabel.show()
	else:
		%NameLabel.hide()
	if icon == null:
		%Icon.hide()
	else:
		%Icon.show()
		%Icon.texture = icon

func prepare_textbox(history_root:Node) -> void:
	%TextBox.add_theme_font_override("normal_font", history_root.history_font_normal)
	%NameLabel.add_theme_font_override("font", history_root.history_font_normal)
	%NameLabel.add_theme_font_size_override("font_size", history_root.history_font_size)
	%TextBox.add_theme_font_override("bold_font", history_root.history_font_bold)
	%TextBox.add_theme_font_override("italics_font", history_root.history_font_italics)
	%TextBox.add_theme_font_size_override("normal_font_size", history_root.history_font_size)
	%TextBox.add_theme_font_size_override("bold_font_size", history_root.history_font_size)
	%TextBox.add_theme_font_size_override("italics_font_size", history_root.history_font_size)
