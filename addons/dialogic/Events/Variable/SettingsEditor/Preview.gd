@tool
extends Control

# This preview is used in the variables editor (Settings)

func set_text(text):
	$Panel/HBox/Label.text = text
	
func _ready():
	$Panel/HBox/TextureRect.texture = get_icon("TripleBar", "EditorIcons")
	$Panel.self_modulate = get_color("prop_subGroup", "Editor")
