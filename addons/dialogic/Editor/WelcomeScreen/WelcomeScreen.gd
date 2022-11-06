@tool
extends ColorRect

func _ready():
	hide()
	$Panel.self_modulate = get_theme_color("dark_color_3", "Editor")
	%CloseButton.icon = get_theme_icon("GuiClose", "EditorIcons")

func _on_restart_godot_button_pressed():
	find_parent('EditorView').plugin_reference.get_editor_interface().restart_editor()

func _on_visit_wiki_button_pressed():
	OS.shell_open("https://github.com/coppolaemilio/dialogic/wiki")

func _on_join_discord_button_pressed():
	OS.shell_open("https://discord.com/invite/2hHQzkf2pX")

func _on_close_button_pressed():
	hide()


func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		hide()
