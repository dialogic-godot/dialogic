@tool
extends PanelContainer

func _ready():
	var info_font_settings :LabelSettings = load("res://addons/dialogic/Editor/Common/HintLabelSettings.tres")
	info_font_settings.font = get_theme_font("doc_italic", "EditorFonts")
	info_font_settings.font_size = get_theme_font_size('font_size', 'Label')
	info_font_settings.font_color = get_theme_color("accent_color", "Editor")
	
	hide()
	visibility_changed.connect(_on_visibility_changed)
	
	# Subsystems
	for script in DialogicUtil.get_event_scripts():
		for subsystem in load(script).new().get_required_subsystems():
			if subsystem.has('settings'):
				$Tabs.add_child(load(subsystem.settings).instantiate())
	refresh()

func _on_visibility_changed():
	if visible:
		refresh()
	else:
		close()

func refresh():
	for child in $Tabs.get_children():
		if child.has_method('refresh'):
			child.refresh()

func close():
	for child in $Tabs.get_children():
		if child.has_method('_about_to_close'):
			child._about_to_close()
	hide()
