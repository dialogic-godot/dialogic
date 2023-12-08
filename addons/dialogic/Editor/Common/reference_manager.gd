@tool
extends PanelContainer


func _ready() -> void:
	if get_parent() is SubViewport:
		return

	self_modulate = get_theme_color("background", "Editor")

	$Tabs.add_theme_color_override("font_selected_color", get_theme_color("accent_color", "Editor"))
	$Tabs.add_theme_font_override("font", get_theme_font("main_button_font", "EditorFonts"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
