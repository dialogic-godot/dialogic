@tool
extends PanelContainer


func _ready() -> void:
	if get_parent() is SubViewport:
		return

	add_theme_stylebox_override("panel", get_theme_stylebox("Background", "EditorStyles"))

	$Tabs.add_theme_color_override("font_selected_color", get_theme_color("accent_color", "Editor"))
	$Tabs.add_theme_font_override("font", get_theme_font("main_button_font", "EditorFonts"))


func open():
	show()
	$Tabs/BrokenReferences.update_indicator()
