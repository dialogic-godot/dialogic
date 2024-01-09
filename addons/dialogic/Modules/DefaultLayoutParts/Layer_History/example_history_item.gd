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
