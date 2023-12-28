extends Container

@onready var text_box : RichTextLabel = %TextBox
@onready var name_label : Label = %NameLabel
@onready var icon_node : TextureRect = %Icon


func load_info(text:String, character:String = "", character_color: Color =Color(), icon:Texture= null) -> void:
	text_box.text = text
	if character:
		name_label.text = character
		name_label.add_theme_color_override('font_color', character_color)
		name_label.show()
	else:
		name_label.hide()
	if icon == null:
		icon_node.hide()
	else:
		icon_node.show()
		icon_node.texture = icon

#
#func prepare_textbox(history_root:Node) -> void:
	#text_box.add_theme_font_override("normal_font", history_root.history_font_normal)
	#name_label.add_theme_font_override("font", history_root.history_font_normal)
	#name_label.add_theme_font_size_override("font_size", history_root.history_font_size)
	#text_box.add_theme_font_override("bold_font", history_root.history_font_bold)
	#text_box.add_theme_font_override("italics_font", history_root.history_font_italics)
	#text_box.add_theme_font_size_override("normal_font_size", history_root.history_font_size)
	#text_box.add_theme_font_size_override("bold_font_size", history_root.history_font_size)
	#text_box.add_theme_font_size_override("italics_font_size", history_root.history_font_size)
