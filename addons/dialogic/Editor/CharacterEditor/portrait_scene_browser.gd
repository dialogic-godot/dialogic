@tool
extends Control

var ListItem := load("res://addons/dialogic/Editor/Common/BrowserItem.tscn")

enum Types {ALL, GENERAL, PRESET}
var current_type := Types.ALL
var current_info := {}

var portrait_scenes_info := {}

signal activate_part(part_info:Dictionary)


func _ready() -> void:
	collect_portrait_scenes()

	%Search.right_icon = get_theme_icon("Search", "EditorIcons")
	%CloseButton.icon = get_theme_icon("Close", "EditorIcons")

	get_parent().close_requested.connect(_on_close_button_pressed)
	get_parent().visibility_changed.connect(func():if get_parent().visible: open())


func collect_portrait_scenes() -> void:
	for indexer in DialogicUtil.get_indexers():
		for element in indexer._get_portrait_scene_presets():
			portrait_scenes_info[element.get('path', '')] = element


func open() -> void:
	collect_portrait_scenes()
	load_parts()


func is_premade_portrait_scene(scene_path:String) -> bool:
	return scene_path in portrait_scenes_info


func load_parts() -> void:
	for i in %PartGrid.get_children():
		i.queue_free()

	%Search.placeholder_text = "Search for "
	%Search.text = ""
	match current_type:
		Types.GENERAL: %Search.placeholder_text += "general portrait scenes"
		Types.PRESET: %Search.placeholder_text += "portrait scene presets"
		Types.ALL: %Search.placeholder_text += "general portrait scenes and presets"

	for info in portrait_scenes_info.values():
		var type: String = info.get('type', '_')
		if (current_type == Types.GENERAL and type != "General") or (current_type == Types.PRESET and type != "Preset"):
			continue

		var item: Node = ListItem.instantiate()
		item.load_info(info)
		%PartGrid.add_child(item)
		item.set_meta('info', info)
		item.clicked.connect(_on_item_clicked.bind(item, info))
		item.focused.connect(_on_item_clicked.bind(item, info))
		item.double_clicked.connect(emit_signal.bind('activate_part', info))

	await get_tree().process_frame

	if %PartGrid.get_child_count() > 0:
		%PartGrid.get_child(0).clicked.emit()
		%PartGrid.get_child(0).grab_focus()


func _on_item_clicked(item: Node, info:Dictionary) -> void:
	load_part_info(info)


func load_part_info(info:Dictionary) -> void:
	current_info = info
	%PartTitle.text = info.get('name', 'Unknown Part')
	%PartAuthor.text = "by "+info.get('author', 'Anonymus')
	%PartDescription.text = info.get('description', '')

	if info.get('preview_image', null) and ResourceLoader.exists(info.preview_image[0]):
		%PreviewImage.texture = load(info.preview_image[0])
		%PreviewImage.show()
	else:
		%PreviewImage.hide()

	match info.type:
		"General":
			%ActivateButton.text = "Use this scene"
			%TypeDescription.text = "This is a general use scene, it can be used directly."
		"Preset":
			%ActivateButton.text = "Customize this scene"
			%TypeDescription.text = "This is a preset you can use for a custom portrait scene. Dialogic will promt you to save a copy of this scene that you can then use and customize."
		"Default":
			%ActivateButton.text = "Use default scene"
			%TypeDescription.text = ""
		"Custom":
			%ActivateButton.text = "Select a custom scene"
			%TypeDescription.text = ""

	if info.get("documentation", ""):
		%DocumentationButton.show()
		%DocumentationButton.uri = info.documentation
	else:
		%DocumentationButton.hide()


func _on_activate_button_pressed() -> void:
	activate_part.emit(current_info)


func _on_close_button_pressed() -> void:
	get_parent().hide()


func _on_search_text_changed(new_text: String) -> void:
	for item in %PartGrid.get_children():
		if new_text.is_empty():
			item.show()
			continue

		if new_text.to_lower() in item.get_meta('info').name.to_lower():
			item.show()
			continue

		item.hide()
