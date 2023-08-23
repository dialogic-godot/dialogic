@tool
extends MarginContainer

var ListItem := load(DialogicUtil.get_module_path('LayoutEditor').path_join("Components/StyleItem.tscn"))
@onready var style_editor := find_parent('StyleEditor')

var recently_used := []

var currently_previewed_layout : String 
var currently_section_is_suggestions := false

func _ready():
	recently_used = DialogicUtil.get_editor_setting('recent_layouts', [])
	%LayoutSearch.right_icon = get_theme_icon("Search", "EditorIcons")
	%Back.icon = get_theme_icon("Back", "EditorIcons")
	
	
	%LayoutPreviewPanel.self_modulate = get_theme_color("background", "Editor").lerp(get_theme_color("dark_color_2", "Editor"),0.8)
	%LayoutAuthor.add_theme_font_size_override("font_size", get_theme_font_size("output_source_size", "EditorFonts"))
	%LayoutDescription.add_theme_font_size_override("font_size", get_theme_font_size("output_source_size", "EditorFonts"))
	%Previous.icon = get_theme_icon("Back", "EditorIcons")
	%Next.icon = get_theme_icon("Forward", "EditorIcons")
	%ClosePreview.icon = get_theme_icon("Close", "EditorIcons")
	%ActivateLayoutButton.icon = get_theme_icon("StatusSuccess", "EditorIcons")
	
	%LayoutPreview.hide()


func load_layout_selection() -> void:
	for i in %LayoutSuggestions.get_children():
		i.queue_free()
	for i in %AllLayouts.get_children():
		i.queue_free()
	
	var custom_item :Node= ListItem.instantiate()
	custom_item.load_info({'name':'Select Custom', 'preview_image': ["custom"], 'description':"Select a scene you've made yourself."})
	custom_item.base_size = 0.7
	custom_item.clicked.connect(_on_custom_layout_pressed)
	%LayoutSuggestions.add_child(custom_item)
	
	for i in recently_used:
		var item :Node= ListItem.instantiate()
		item.base_size = 0.7
		if i in style_editor.preset_info:
			item.load_info(style_editor.preset_info[i])
		else:
			item.load_info({'name':i.get_file().trim_suffix('.'+i.get_extension()), 'preview_image': [i], 'description':i})
		item.clicked.connect(_open_layout_info.bind(i, true))
		item.middle_clicked.connect(suggestion_removed.bind(i))
		item.set_meta('style', i)
		%LayoutSuggestions.add_child(item)
	
	
	for i in style_editor.preset_info:
		var item :Node= ListItem.instantiate()
		item.load_info(style_editor.preset_info[i])
		item.clicked.connect(_open_layout_info.bind(i))
		item.set_meta('style', i)
		%AllLayouts.add_child(item)


func suggestion_removed(path):
	for i in %LayoutSuggestions.get_children():
		if i.has_meta('style') and i.get_meta('style', null) == path:
			i.queue_free()
	recently_used.erase(path)
	DialogicUtil.set_editor_setting('recent_layouts', recently_used)


func open(current_layout:String=""):
	show()
	load_layout_selection()
	if current_layout.is_empty():
		return
	for i in %AllLayouts.get_children():
		i.set_current(i.get_meta('style') == current_layout)
		i.modulate = Color.TRANSPARENT
		i.create_tween().tween_property(i, 'modulate', Color.WHITE, 0.05).set_delay(i.get_index()*0.05)


func _on_custom_layout_pressed() -> void:
	find_parent('EditorView').godot_file_dialog(_on_custom_layout_selected, "*.tscn, **.scn; Custom Layout scene", FileDialog.FILE_MODE_OPEN_FILE, "Open custom layout scene")


func _on_custom_layout_selected(path:String) -> void:
	currently_previewed_layout = path
	_on_activate_layout_button_pressed()


func _on_back_pressed():
	hide()
	style_editor.get_node('%StyleSettings').show()


func _open_layout_info(layout_path:String, suggestion_section:=false) -> void:
	if !layout_path in style_editor.preset_info and !layout_path.ends_with('scn'):
		return
	
	currently_section_is_suggestions = suggestion_section
	currently_previewed_layout = layout_path
	
	var info := {}
	if layout_path in style_editor.preset_info:
		info = style_editor.preset_info[layout_path]
	else:
		info = {'name':layout_path.get_file().trim_suffix('.'+layout_path.get_extension()), 'preview_image': [layout_path], 'author':'Custom Scene', 'description':layout_path}
	%LayoutName.text = info.name
	%LayoutName.tooltip_text = layout_path
	%LayoutAuthor.text = info.author
	%LayoutDescription.text = info.description
	
	if info.preview_image[0].ends_with('scn'):
		DialogicUtil.get_dialogic_plugin().get_editor_interface().get_resource_previewer().queue_resource_preview(info.preview_image[0], self, 'set_scene_preview', null)
	else:
		%LayoutPreviewImageBig.texture = load(info.preview_image[0])
	%LayoutPreview.show()
	%ActivateLayoutButton.grab_focus()

func set_scene_preview(path:String, preview:Texture2D, thumbnail:Texture2D, userdata:Variant) -> void:
	if preview:
		%LayoutPreviewImageBig.texture = preview
	else:
		%LayoutPreviewImageBig.texture = get_theme_icon("PackedScene", "EditorIcons")
	


func _on_close_preview_pressed():
	for i in %AllLayouts.get_children():
		if i.get_meta('style') == currently_previewed_layout:
			i.grab_focus()
	%LayoutPreview.hide()


func _on_layout_preview_gui_input(event):
	if event is InputEventMouseButton:
		%LayoutPreview.hide()


func _on_preview_next_pressed():
	var container := %AllLayouts
	if currently_section_is_suggestions: container = %LayoutSuggestions
	for idx in range(container.get_child_count()):
		if container.get_child(idx).get_meta('style', null) == %LayoutName.tooltip_text:
			_open_layout_info(container.get_child(wrapi(idx+1, 0, container.get_child_count())).get_meta('style', ''))
			return


func _on_preview_previous_pressed():
	var container := %AllLayouts
	if currently_section_is_suggestions: container = %LayoutSuggestions
	for idx in range(container.get_child_count()):
		if container.get_child(idx).get_meta('style', null) == %LayoutName.tooltip_text:
			_open_layout_info(container.get_child(wrapi(idx-1, 0, container.get_child_count())).get_meta('style', ''))
			return


func _on_activate_layout_button_pressed():
	if !currently_previewed_layout in recently_used:
		recently_used.append(currently_previewed_layout)
		DialogicUtil.set_editor_setting('recent_layouts', recently_used)
	style_editor.set_layout(currently_previewed_layout)
	_on_close_preview_pressed()
	_on_back_pressed()


func _on_layout_search_text_changed(new_text:String) -> void:
	for i in %AllLayouts.get_children():
		if new_text.is_empty() or (new_text.to_lower() in i.get_meta('style').get_file().to_lower()) or (
			new_text.to_lower() in style_editor.preset_info[i.get_meta('style')].name.to_lower()):
			i.show()
		else:
			i.hide()
