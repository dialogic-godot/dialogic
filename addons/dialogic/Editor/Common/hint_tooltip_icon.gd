@tool
extends TextureRect

@export_multiline var hint_text = ""

func _ready():
	texture = get_theme_icon("NodeInfo", "EditorIcons")
	modulate = get_theme_color("contrast_color_1", "Editor")
	tooltip_text = hint_text
