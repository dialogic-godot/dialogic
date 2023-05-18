@tool
extends DialogicEditor

## A Main page in the dialogic editor.

var tips : PackedStringArray = []

func _ready():
	self_modulate = get_theme_color("font_color", "Editor")
	self_modulate.a = 0.2
	
	var edit_scale := DialogicUtil.get_editor_scale()
	%HomePageBox.custom_minimum_size = Vector2(600, 350)*edit_scale

	%VersionLabel.set('theme_override_font_sizes/font_size', 10 * edit_scale)
	var plugin_cfg := ConfigFile.new()
	plugin_cfg.load("res://addons/dialogic/plugin.cfg")
	%VersionLabel.text = plugin_cfg.get_value('plugin', 'version', 'unknown version')
	
	%BottomPanel.self_modulate = get_theme_color("dark_color_3", "Editor")

	%RandomTipLabel.add_theme_color_override("font_color", get_theme_color("property_color_z", "Editor"))
	%RandomTipMoreButton.icon = get_theme_icon("ExternalLink", "EditorIcons")



func _register():
	editors_manager.register_simple_editor(self)
	get_parent().set_tab_icon(get_index(), load("res://addons/dialogic/Editor/Images/plugin-icon.svg"))
	get_parent().set_tab_title(get_index(), '')
	
	editors_manager.add_custom_button('Wiki', 
			get_theme_icon("Help", "EditorIcons"), 
			self).pressed.connect(_on_wiki_button_pressed)
			
	editors_manager.add_custom_button('Discord', 
			get_theme_icon("CryptoKey", "EditorIcons"), 
			self).pressed.connect(_on_discord_button_pressed)
	
	self.alternative_text = "Welcome to dialogic!"


func _on_discord_button_pressed() -> void:
	OS.shell_open("https://discord.gg/2hHQzkf2pX")


func _on_wiki_button_pressed() -> void:
	OS.shell_open("https://github.com/coppolaemilio/dialogic/wiki")


func _on_wiki_getting_started_button_pressed():
	OS.shell_open("https://github.com/coppolaemilio/dialogic/wiki/Tutorial:-Getting-Started")


func _on_bug_request_button_pressed():
	OS.shell_open("https://github.com/coppolaemilio/dialogic/issues/new/choose")


func _on_donate_button_pressed():
	OS.shell_open("https://www.patreon.com/coppolaemilio")


func show_tip(text:String='', action:String='') -> void:
	if text.is_empty():
		%TipBox.hide()
		return
	
	%TipBox.show()
	%RandomTip.text = '[i]'+text
	
	if action.is_empty():
		%RandomTipMoreButton.hide()
		return
	
	%RandomTipMoreButton.show()
	
	if %RandomTipMoreButton.pressed.is_connected(_on_tip_action):
		%RandomTipMoreButton.pressed.disconnect(_on_tip_action)
	%RandomTipMoreButton.pressed.connect(_on_tip_action.bind(action))


func _on_tip_action(action:String) -> void:
	if action.begins_with('https://'):
		OS.shell_open(action)
		return
	elif action.begins_with('editor://'):
		var editor_name := action.trim_prefix('editor://').get_slice('->',0)
		var extra_info := action.trim_prefix('editor://').get_slice('->',1)
		print(editors_manager.editors)
		if editor_name in editors_manager.editors:
			editors_manager.open_editor(editors_manager.editors[editor_name].node, false, extra_info)
			return

	print("Tip button doesn't do anything (", action, ")")


func _open(extra_info:Variant="") -> void:
	if tips.is_empty():
		var file := FileAccess.open('res://addons/dialogic/Editor/HomePage/tips.txt', FileAccess.READ)
		tips = file.get_as_text().split('\n')
	
	randomize()
	var tip := tips[randi()%len(tips)]
	show_tip(tip.get_slice(';',0).strip_edges(), tip.get_slice(';',1).strip_edges())
