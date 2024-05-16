@tool
extends Container

signal clicked
signal middle_clicked
signal double_clicked
signal focused

var base_size = 1


func _ready() -> void:
	if get_parent() is SubViewport:
		return

	%Name.add_theme_font_override("font", get_theme_font("bold", "EditorFonts"))
	custom_minimum_size = base_size*Vector2(200, 150) * DialogicUtil.get_editor_scale()
	%CurrentIcon.texture = get_theme_icon("Favorites", "EditorIcons")
	if %Image.texture == null:
		%Image.texture = get_theme_icon("ImportFail", "EditorIcons")
		%Image.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED


func load_info(info:Dictionary) -> void:
	%Name.text = info.name
	if info.preview_image[0] == 'custom':
		await ready
		%Image.texture = get_theme_icon("CreateNewSceneFrom", "EditorIcons")
		%Image.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		%Panel.self_modulate = get_theme_color("property_color_z", "Editor")
	elif info.preview_image[0].ends_with('scn'):
		DialogicUtil.get_dialogic_plugin().get_editor_interface().get_resource_previewer().queue_resource_preview(info.preview_image[0], self, 'set_scene_preview', null)
	elif ResourceLoader.exists(info.preview_image[0]):
		%Image.texture = load(info.preview_image[0])

	if ResourceLoader.exists(info.get('icon', '')):
		%Icon.get_parent().show()
		%Icon.texture = load(info.get('icon'))
	else:
		%Icon.get_parent().hide()

	tooltip_text = info.description


func set_scene_preview(path:String, preview:Texture2D, thumbnail:Texture2D, userdata:Variant) -> void:
	if preview:
		%Image.texture = preview
	else:
		%Image.texture = get_theme_icon("PackedScene", "EditorIcons")



func set_current(current:bool):
	%CurrentIcon.visible = current


func _on_mouse_entered():
	%HoverBG.show()


func _on_mouse_exited():
	%HoverBG.hide()


func _on_gui_input(event):
	if event.is_action_pressed('ui_accept') or event.is_action_pressed("ui_select") or (
				event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		clicked.emit()
		if not event is InputEventMouseButton or event.double_click:
			double_clicked.emit()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
		middle_clicked.emit()


func _on_focus_entered():
	$FocusFG.show()
	focused.emit()


func _on_focus_exited():
	$FocusFG.hide()
