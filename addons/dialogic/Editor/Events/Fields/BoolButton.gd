@tool
extends Button

## Event block field for boolean values.

signal value_changed
var property_name : String


func _ready() -> void:
	add_theme_color_override("icon_normal_color", get_theme_color("disabled_font_color", "Editor"))
	add_theme_color_override("icon_hover_color", get_theme_color("warning_color", "Editor"))
	add_theme_color_override("icon_pressed_color", get_theme_color("icon_saturation", "Editor"))
	add_theme_color_override("icon_hover_pressed_color", get_theme_color("warning_color", "Editor"))
	add_theme_color_override("icon_focus_color", get_theme_color("disabled_font_color", "Editor"))
	toggled.connect(_on_value_changed)


func set_value(value:bool) -> void:
	button_pressed = value


func _on_value_changed(value:bool) -> void:
	value_changed.emit(property_name, value)
