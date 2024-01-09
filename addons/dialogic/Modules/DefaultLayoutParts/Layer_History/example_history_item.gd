extends Container

func get_text_box() -> RichTextLabel:
	return %TextBox


func get_name_label() -> Label:
	return %NameLabel


func get_icon() -> TextureRect:
	return %Icon


func load_info(text:String, character:String = "", character_color: Color =Color(), icon:Texture= null) -> void:
	get_text_box().text = text
	var name_label : Label = get_name_label()
	if character:
		name_label.text = character
		name_label.add_theme_color_override('font_color', character_color)
		name_label.show()
	else:
		name_label.hide()
	
	var icon_node : TextureRect = get_icon()
	if icon == null:
		icon_node.hide()
	else:
		icon_node.show()
		icon_node.texture = icon