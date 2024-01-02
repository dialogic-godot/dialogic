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

#
#func prepare_textbox(history_root:Node) -> void:
	#get_text_box().add_theme_font_override("normal_font", history_root.history_font_normal)
	#get_name_label().add_theme_font_override("font", history_root.history_font_normal)
	#get_name_label().add_theme_font_size_override("font_size", history_root.history_font_size)
	#get_text_box().add_theme_font_override("bold_font", history_root.history_font_bold)
	#get_text_box().add_theme_font_override("italics_font", history_root.history_font_italics)
	#get_text_box().add_theme_font_size_override("normal_font_size", history_root.history_font_size)
	#get_text_box().add_theme_font_size_override("bold_font_size", history_root.history_font_size)
	#get_text_box().add_theme_font_size_override("italics_font_size", history_root.history_font_size)
