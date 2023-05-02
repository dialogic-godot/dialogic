@tool
extends PopupMenu

var current_event : Node = null

func _ready():
	clear()
	add_icon_item(get_theme_icon("Help", "EditorIcons"), "Documentation")
	add_separator()
	add_icon_item(get_theme_icon("ArrowUp", "EditorIcons"), "Move up")
	add_icon_item(get_theme_icon("ArrowDown", "EditorIcons"), "Move down")
	add_separator()
	add_icon_item(get_theme_icon("Remove", "EditorIcons"), "Delete")
	
	var menu_background := StyleBoxFlat.new()
	menu_background.bg_color = get_parent().get_theme_color("base_color", "Editor")
	add_theme_stylebox_override('panel', menu_background)
	add_theme_stylebox_override('hover', get_theme_stylebox("FocusViewport", "EditorStyles"))
	add_theme_color_override('font_color_hover', get_parent().get_theme_color("accent_color", "Editor"))
