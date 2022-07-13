tool
extends PopupMenu

func _ready():
	clear()
	add_icon_item(get_icon("Help", "EditorIcons"), "Documentation")
	add_separator()
	add_icon_item(get_icon("ArrowUp", "EditorIcons"), "Move up")
	add_icon_item(get_icon("ArrowDown", "EditorIcons"), "Move down")
	add_separator()
	add_icon_item(get_icon("Remove", "EditorIcons"), "Delete")
	
	var menu_background = load("res://addons/dialogic/Editor/Events/styles/ResourceMenuPanelBackground.tres")
	menu_background.bg_color = get_color("base_color", "Editor")
	add_stylebox_override('panel', menu_background)
	add_stylebox_override('hover', StyleBoxEmpty.new())
	add_color_override('font_color_hover', get_color("accent_color", "Editor"))
