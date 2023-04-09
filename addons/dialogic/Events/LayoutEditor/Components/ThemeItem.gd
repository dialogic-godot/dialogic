@tool
extends HBoxContainer

var theme_name := 'Dialogic Theme'
var author := 'Emi'
var preview_image = null
var path: String
var description: String = ""

signal activate_theme


func _ready() -> void:
	%Name.text = theme_name
	%Name.add_theme_font_override("font", get_theme_font("bold", "EditorFonts"))
	%Author.text = author
	%Author.self_modulate = Color(1,1,1,0.6)
	%ActiveButton.pressed.connect(_on_button_pressed)
	$TextureRect.texture = preview_image
	tooltip_text = description


func active_state(value: bool) -> void:
	%ActiveButton.button_pressed = value


func _on_button_pressed() -> void:
	emit_signal('activate_theme', self)
