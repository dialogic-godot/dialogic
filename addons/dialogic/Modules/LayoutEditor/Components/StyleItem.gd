@tool
extends Container

signal clicked
signal middle_clicked

var base_size = 1


func _ready() -> void:
	%Name.add_theme_font_override("font", get_theme_font("bold", "EditorFonts"))
	custom_minimum_size = base_size*Vector2(200, 150)*DialogicUtil.get_editor_scale()
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
	else:
		%Image.texture = load(info.preview_image[0])
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
	if Input.is_action_just_pressed('ui_accept') or Input.is_action_just_pressed("ui_select") or (
				event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		clicked.emit()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
		middle_clicked.emit()


func _on_focus_entered():
	$FocusFG.show()


func _on_focus_exited():
	$FocusFG.hide()
