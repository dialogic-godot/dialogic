@tool
extends PanelContainer


var shortcuts := [

	{"shortcut":"Ctrl+T", 			"text":"Add Text event", "editor":"VisualEditor"},
	{"shortcut":"Ctrl+Shift+T", "text":"Add Text event with current character", "editor":"VisualEditor"},
	{"shortcut":"Ctrl+Alt+T", 	"text":"Add Text event with previous character", "editor":"VisualEditor"},
	{"shortcut":"Ctrl+E", 			"text":"Add Character join event", "editor":"VisualEditor"},
	{"shortcut":"Ctrl+Shift+E", "text":"Add Character update event", "editor":"VisualEditor"},
	{"shortcut":"Ctrl+Alt+E", 	"text":"Add Character leave event", "editor":"VisualEditor"},
	{"shortcut":"Ctrl+J", 			"text":"Add Jump event", "editor":"VisualEditor"},
	{"shortcut":"Ctrl+L", 			"text":"Add Label event", "editor":"VisualEditor"},
	{},
	{"shortcut":"Alt+Up", 		"text":"Move selected events/lines up"},
	{"shortcut":"Alt+Down", 	"text":"Move selected events/lines down"},
	{},
	{"shortcut":"Ctrl+F", 			"text":"Search"},
	{"shortcut":"Ctrl+R", 			"text":"Replace"},
	{},
	{"shortcut":"Ctrl+F5", 			"text":"Play timeline", "platform":"-macOS"},
	{"shortcut":"Ctrl+B", 			"text":"Play timeline", "platform":"macOS"},
	{"shortcut":"Ctrl+F6", 			"text":"Play timeline from here", "platform":"-macOS"},
	{"shortcut":"Ctrl+Shift+B", 	"text":"Play timeline from here", "platform":"macOS"},

	{},
	{"shortcut":"Ctrl+C", 			"text":"Copy"},
	{"shortcut":"Ctrl+V", 			"text":"Paste"},
	{"shortcut":"Ctrl+D", 			"text":"Duplicate selected events/lines"},
	{"shortcut":"Ctrl+X", 			"text":"Cut selected events/lines"},
	{"shortcut":"Ctrl+K", 			"text":"Toggle Comment" , "editor":"TextEditor"},
	{"shortcut":"Delete", 			"text":"Delete events", "editor":"VisualEditor"},
	{},
	{"shortcut":"Ctrl+A", 			"text":"Select All"},
	{"shortcut":"Ctrl+Shift+A", 	"text":"Select Nothing", "editor":"VisualEditor"},
	{"shortcut":"Up", 				"text":"Select previous event", "editor":"VisualEditor"},
	{"shortcut":"Down", 			"text":"Select next event", "editor":"VisualEditor"},
	{},
	{"shortcut":"Ctrl+Z", 			"text":"Undo"},
	{"shortcut":"Ctrl+Shift+Z", 	"text":"Redo"},
	{},
]

func _process_shortcuts_for_platform(shortcuts: Array) -> Array:
	var formatted = []
	for shortcut in shortcuts:
		if not (shortcut is Dictionary and "shortcut" in shortcut):
			continue

		var shortcut_text = shortcut["shortcut"]

		if OS.has_feature("macos"):
			shortcut_text = shortcut_text.replace("Ctrl", "Command")
			shortcut_text = shortcut_text.replace("Alt", "Opt")

		var entry = shortcut.duplicate()
		entry["shortcut"] = shortcut_text
		formatted.append(entry)

	return formatted

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if owner.get_parent() is SubViewport:
		return

	%CloseShortcutPanel.icon = get_theme_icon("Close", "EditorIcons")
	get_theme_stylebox("panel").bg_color = get_theme_color("dark_color_3", "Editor")


func reload_shortcuts() -> void:
	for i in %ShortcutList.get_children():
		i.queue_free()

	var is_text_editor: bool = %TextEditor.visible
	for i in _process_shortcuts_for_platform(shortcuts):
		if i.is_empty():
			%ShortcutList.add_child(HSeparator.new())
			%ShortcutList.add_child(HSeparator.new())
			continue

		if "editor" in i and not get_node("%"+i.editor).visible:
			continue

		if "platform" in i:
			var platform := OS.get_name()
			if not (platform == i.platform.trim_prefix("-") != i.platform.begins_with("-")):
				continue

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 0)
		for key_text in i.shortcut.split("+"):
			if hbox.get_child_count():
				var plus_l := Label.new()
				plus_l.text = "+"
				hbox.add_child(plus_l)

			var key := Button.new()
			if key_text == "Up":
				key.icon = get_theme_icon("ArrowUp", "EditorIcons")
			elif key_text == "Down":
				key.icon = get_theme_icon("ArrowDown", "EditorIcons")
			else:
				key_text = key_text.replace("Alt/Opt", "Opt" if OS.get_name() == "macOS" else "Alt")
				key.text = key_text
			key.disabled = true
			key.theme_type_variation = "ShortcutKeyLabel"
			key.add_theme_font_override("font", get_theme_font("source", "EditorFonts"))
			hbox.add_child(key)

		%ShortcutList.add_child(hbox)

		var text := Label.new()
		text.text = i.text.replace("events/lines", "lines" if is_text_editor else "events")
		text.theme_type_variation = "DialogicHintText2"
		%ShortcutList.add_child(text)


func open():
	if visible:
		close()
		return
	reload_shortcuts()

	show()
	await get_tree().process_frame
	size = get_parent().size - Vector2(100, 100)*DialogicUtil.get_editor_scale()
	size.x = %ShortcutList.get_minimum_size().x + 100
	size.y = min(size.y, %ShortcutList.get_minimum_size().y+100)
	global_position = get_parent().global_position+get_parent().size/2-size/2


func _on_close_shortcut_panel_pressed() -> void:
	close()

func close() -> void:
	hide()
