@tool
extends TextureRect

@export_multiline var hint_text = ""

func _ready():
	texture = get_theme_icon("NodeInfo", "EditorIcons")
	modulate = get_theme_color("readonly_color", "Editor")
	tooltip_text = hint_text
