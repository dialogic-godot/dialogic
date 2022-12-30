@tool
extends Control

# This preview is used in the variables editor (Settings)

func set_text(text):
	$Panel/HBox/Label.text = text
	
func _ready():
	$Panel/HBox/TextureRect.texture = get_theme_icon("TripleBar", "EditorIcons")
	$Panel.self_modulate = get_theme_color("prop_subGroup", "Editor")
