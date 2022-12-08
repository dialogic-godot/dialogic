@tool
extends DialogicEditor

## A Main page in the dialogic editor.

func _ready():
	var edit_scale := DialogicUtil.get_editor_scale()
	var min_height := 0
	for box in %BoxHolder.get_children():
		box.self_modulate = get_theme_color("accent_color", "Editor")
		box.custom_minimum_size.x = 220 * edit_scale
		if box.get_index() < ceilf(%BoxHolder.get_child_count()/2.0):
			min_height += box.size.y
	
	%VersionLabel.set('theme_override_font_sizes/font_size', 20 * edit_scale)
	$CenterContainer/ScrollContainer.custom_minimum_size.x = 440 *edit_scale
	%BoxHolder.custom_minimum_size.y = min_height+100*edit_scale
	set('theme_override_constants/separation', 30*edit_scale)


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


func _on_wiki_box_button_pressed():
	OS.shell_open("https://github.com/coppolaemilio/dialogic/wiki/Tutorial:-Getting-Started")


func _on_sharing_box_button_pressed():
	_on_discord_button_pressed()

func _on_bug_box_button_pressed():
	OS.shell_open("https://github.com/coppolaemilio/dialogic/issues/new/choose")

func _on_restart_box_button_pressed():
	find_parent('EditorView').plugin_reference.get_editor_interface().restart_editor()
