@tool
extends Control

var ListItem := load(DialogicUtil.get_module_path('StyleEditor').path_join("Components/StyleItem.tscn"))
enum Types {ALL, STYLES, LAYER, LAYOUT_BASE}

var current_type := Types.ALL
var style_part_info := []
var premade_scenes_reference := {}

signal activate_part(part_info:Dictionary)

var current_info := {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%Search.right_icon = get_theme_icon("Search", "EditorIcons")
	collect_style_parts()


func collect_style_parts() -> void:
	for indexer in DialogicUtil.get_indexers():
		for layout_part in indexer._get_layout_parts():
			style_part_info.append(layout_part)
			if not layout_part.get('path', '').is_empty():
				premade_scenes_reference[layout_part['path']] = layout_part


func is_premade_style_part(scene_path:String) -> bool:
	return scene_path in premade_scenes_reference


func load_parts() -> void:
	for i in %PartGrid.get_children():
		i.queue_free()

	%Search.placeholder_text = "Search for "
	%Search.text = ""
	match current_type:
		Types.STYLES:
			%Search.placeholder_text += "premade styles"
		Types.LAYER:
			%Search.placeholder_text += "layer scenes"
		Types.LAYOUT_BASE:
			%Search.placeholder_text += "layout base scenes"
		Types.ALL:
			%Search.placeholder_text += "styles or layout scenes"

	for info in style_part_info:
		var type: String = info.get('type', '_')
		match current_type:
			Types.STYLES:
				if type != "Style":
					continue
			Types.LAYER:
				if type != "Layer":
					continue
			Types.LAYOUT_BASE:
				if type != "Layout Base":
					continue

		var style_item: Node = ListItem.instantiate()
		style_item.load_info(info)
		%PartGrid.add_child(style_item)
		style_item.set_meta('info', info)
		style_item.clicked.connect(_on_style_item_clicked.bind(style_item, info))
		style_item.focused.connect(_on_style_item_clicked.bind(style_item, info))
		style_item.double_clicked.connect(emit_signal.bind('activate_part', info))

	await get_tree().process_frame

	if %PartGrid.get_child_count() > 0:
		%PartGrid.get_child(0).clicked.emit()
		%PartGrid.get_child(0).grab_focus()


func _on_style_item_clicked(item:Node, info:Dictionary) -> void:
	load_part_info(info)


func load_part_info(info:Dictionary) -> void:
	current_info = info
	%PartTitle.text = info.get('name', 'Unknown Part')
	%PartAuthor.text = "by "+info.get('author', 'Anonymus')
	%PartDescription.text = info.get('description', '')

	if info.get('preview_image', null):
		%PreviewImage.texture = load(info.get('preview_image')[0])
		%PreviewImage.show()
	else:
		%PreviewImage.hide()


func _on_activate_button_pressed() -> void:
	activate_part.emit(current_info)


func _on_search_text_changed(new_text: String) -> void:
	for item in %PartGrid.get_children():
		if new_text.is_empty():
			item.show()
			continue

		if new_text.to_lower() in item.get_meta('info').name.to_lower():
			item.show()
			continue

		item.hide()
