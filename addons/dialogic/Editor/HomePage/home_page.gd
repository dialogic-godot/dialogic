@tool
extends DialogicEditor

## A Main page in the dialogic editor.

var tips : Array = []



func _get_icon() -> Texture:
	return load("res://addons/dialogic/Editor/Images/plugin-icon.svg")


func _ready():
	self_modulate = get_theme_color("font_color", "Editor")
	self_modulate.a = 0.2

	var edit_scale := DialogicUtil.get_editor_scale()
	%HomePageBox.custom_minimum_size = Vector2(600, 350)*edit_scale
	%TopPanel.custom_minimum_size.y = 100*edit_scale
	%VersionLabel.set('theme_override_font_sizes/font_size', 10 * edit_scale)
	var plugin_cfg := ConfigFile.new()
	plugin_cfg.load("res://addons/dialogic/plugin.cfg")
	%VersionLabel.text = plugin_cfg.get_value('plugin', 'version', 'unknown version')

	%BottomPanel.self_modulate = get_theme_color("dark_color_3", "Editor")

	%RandomTipLabel.add_theme_color_override("font_color", get_theme_color("property_color_z", "Editor"))
	%RandomTipMoreButton.icon = get_theme_icon("ExternalLink", "EditorIcons")



func _register():
	editors_manager.register_simple_editor(self)

	self.alternative_text = "Welcome to dialogic!"



func _open(extra_info:Variant="") -> void:
	if tips.is_empty():
		var file := FileAccess.open('res://addons/dialogic/Editor/HomePage/tips.txt', FileAccess.READ)
		tips = file.get_as_text().split('\n')
		tips = tips.filter(func(item): return !item.is_empty())

	randomize()
	var tip :String = tips[randi()%len(tips)]
	var text := tip.get_slice(';',0).strip_edges()
	var action := tip.get_slice(';',1).strip_edges()
	if action == text:
		action = ""
	show_tip(text, action)


func show_tip(text:String='', action:String='') -> void:
	if text.is_empty():
		%TipBox.hide()
		%RandomTipLabel.hide()
		return

	%TipBox.show()
	%RandomTipLabel.show()
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
		if editor_name in editors_manager.editors:
			editors_manager.open_editor(editors_manager.editors[editor_name].node, false, extra_info)
			return
	print("Tip button doesn't do anything (", action, ")")
