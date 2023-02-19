@tool
extends Control

# This preview is used in the variables editor (Settings)

func set_text(text:String) -> void:
	$Panel/HBox/Label.text = text
	
func _ready() -> void:
	$Panel.add_theme_stylebox_override('panel', get_theme_stylebox("LaunchPadNormal", "EditorStyles"))
	$Panel/HBox/TextureRect.texture = get_theme_icon("TripleBar", "EditorIcons")
