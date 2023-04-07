@tool
extends HBoxContainer

var theme_name := 'Dialogic Theme'
var author := 'Emi'
var preview_image = null
var path: String

signal activate_theme


func _ready() -> void:
	$VBoxContainer/Name.text = theme_name
	$VBoxContainer/Name.add_theme_font_override("font", get_theme_font("bold", "EditorFonts"))
	$VBoxContainer/Author.text = author
	$VBoxContainer/Author.self_modulate = Color(1,1,1,0.6)
	$VBoxContainer/Button.pressed.connect(_on_button_pressed)
	$TextureRect.texture = preview_image


func _on_button_pressed() -> void:
	emit_signal('activate_theme', self)
