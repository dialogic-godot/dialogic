@tool
extends DialogicEditor

## A Main page in the dialogic editor.



func _register():
	editors_manager.register_simple_editor(self)
	get_parent().set_tab_icon(get_index(), load("res://addons/dialogic/Editor/Images/plugin-icon.svg"))
	get_parent().set_tab_title(get_index(), '')
	
	editors_manager.add_custom_button('Wiki', 
			get_theme_icon("Help", "EditorIcons"), 
			self).pressed.connect(_on_wiki_button_pressed)
			
	editors_manager.add_custom_button('Discord', 
			get_theme_icon("AnimatedSprite3D", "EditorIcons"), 
			self).pressed.connect(_on_discord_button_pressed)


func _on_discord_button_pressed() -> void:
	OS.shell_open("https://discord.gg/2hHQzkf2pX")


func _on_wiki_button_pressed() -> void:
	OS.shell_open("https://github.com/coppolaemilio/dialogic/wiki")
