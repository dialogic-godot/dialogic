@tool
extends Window

## A base for the style/layout and portrait scene browser.

signal item_selected(info:Dictionary)
signal request_reload

var BrowserItem := load("uid://ddlxjde1cx035")

var current_info := {}


func _ready() -> void:
	if get_parent() is SubViewport or owner.get_parent() is SubViewport:
		return

	hide()
	%BrowserTitle.text = title
	%Search.right_icon = get_theme_icon("Search", "EditorIcons")
	%CloseButton.icon = get_theme_icon("Close", "EditorIcons")
	%ReloadButton.icon = get_theme_icon("Reload", "EditorIcons")


func open() -> void:
	popup_centered_ratio(0.6)


func load_items(items:Array[Dictionary], type_name:="") -> void:
	for i in %ItemGrid.get_children():
		i.queue_free()

	%Search.placeholder_text = "Search for " + type_name
	%Search.text = ""

	for info in items:
		var item_node: Node = BrowserItem.instantiate()
		item_node.load_info(info)
		%ItemGrid.add_child(item_node)
		item_node.set_meta("info", info)
		item_node.clicked.connect(_on_item_clicked.bind(item_node, info))
		item_node.focused.connect(_on_item_clicked.bind(item_node, info))
		item_node.double_clicked.connect(emit_signal.bind("item_selected", info))

	await get_tree().process_frame

	if %ItemGrid.get_child_count() > 0:
		%ItemGrid.get_child(0).clicked.emit()
		%ItemGrid.get_child(0).grab_focus()


func _on_item_clicked(_item:Node, info:Dictionary) -> void:
	current_info = info
	%ItemTitle.text = info.get("name", "Unknown Part")
	%ItemAuthor.text = "by "+info.get("author", "Anonymus")
	%ItemDescription.text = info.get("description", "")

	if info.get("preview_image", null):
		%PreviewImage.show()
		if len(info.preview_image) > 1:
			%MultiImageSelects.show()
			for i in %SmallPreviews.get_children():
				i.queue_free()
			var group := ButtonGroup.new()
			for idx in range(info.preview_image.size()):
				var small_preview: Button = preload("uid://bk0flv1l60mri").instantiate()
				%SmallPreviews.add_child(small_preview)
				small_preview.get_child(0).texture = load(info.preview_image[idx])
				small_preview.pressed.connect(load_preview_image.bind(idx))
				small_preview.button_group = group

		else:
			%MultiImageSelects.hide()

		load_preview_image(0)

	else:
		%PreviewImage.hide()
		%MultiImageSelects.hide()


func get_picked_item_info() -> Dictionary:
	var result = await item_selected
	hide()
	return result


func load_preview_image(idx:int=0) -> void:
	if %SmallPreviews.get_child_count():
		%SmallPreviews.get_child(idx).button_pressed = true
	if ResourceLoader.exists(current_info.preview_image[idx]):
		%PreviewImage.texture = load(current_info.preview_image[idx])
	else:
		%PreviewImage.texture = null


func _on_activate_button_pressed() -> void:
	item_selected.emit(current_info)
	hide()


func _on_search_text_changed(new_text: String) -> void:
	for item in %ItemGrid.get_children():
		if new_text.is_empty():
			item.show()
			continue

		if new_text.to_lower() in item.get_meta("info").name.to_lower():
			item.show()
			continue

		item.hide()


func _on_close_requested() -> void:
	item_selected.emit({})
	hide()


func _on_close_button_pressed() -> void:
	_on_close_requested()


func _on_reload_button_pressed() -> void:
	request_reload.emit()
