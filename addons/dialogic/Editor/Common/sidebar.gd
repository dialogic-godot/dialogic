@tool
extends Control

## Script that handles the editor sidebar.

signal file_activated(file_path)

signal content_item_activated(item_name)

signal show_sidebar(show: bool)

@onready var editors_manager = get_parent().get_parent()
@onready var resource_tree: Tree = %ResourceTree
var current_resource_list: Array = []


func _ready() -> void:
	if owner.get_parent() is SubViewport:
		return

	## CONNECTIONS

	editors_manager.resource_opened.connect(_on_editors_resource_opened)
	editors_manager.editor_changed.connect(_on_editors_editor_changed)

	resource_tree.item_activated.connect(_on_resources_tree_item_activated)
	resource_tree.item_mouse_selected.connect(_on_resources_tree_item_clicked)

	%ContentList.item_selected.connect(
		func(idx: int): content_item_activated.emit(%ContentList.get_item_text(idx))
	)

	(%OpenButton as Button).pressed.connect(_show_sidebar)
	(%CloseButton as Button).pressed.connect(_hide_sidebar)

	var editor_scale := DialogicUtil.get_editor_scale()
	## ICONS
	%Logo.texture = load("res://addons/dialogic/Editor/Images/dialogic-logo.svg")
	%Logo.custom_minimum_size.y = 30 * editor_scale
	%Search.right_icon = get_theme_icon("Search", "EditorIcons")

	%ContentList.add_theme_color_override(
		"font_hovered_color", get_theme_color("warning_color", "Editor")
	)
	%ContentList.add_theme_color_override(
		"font_selected_color", get_theme_color("property_color_z", "Editor")
	)

	## MARGINS
	%VBoxPrimary/Margin.set(
		"theme_override_constants/margin_left",
		get_theme_constant("base_margin", "Editor") * editor_scale
	)
	%VBoxPrimary/Margin.set(
		"theme_override_constants/margin_bottom",
		get_theme_constant("base_margin", "Editor") * editor_scale
	)

	## RIGHT CLICK MENU
	%RightClickMenu.clear()
	%RightClickMenu.add_icon_item(get_theme_icon("Remove", "EditorIcons"), "Remove From List", 1)
	%RightClickMenu.add_separator()
	%RightClickMenu.add_icon_item(get_theme_icon("ActionCopy", "EditorIcons"), "Copy Identifier", 4)
	%RightClickMenu.add_separator()
	%RightClickMenu.add_icon_item(get_theme_icon("Filesystem", "EditorIcons"), "Show in FileSystem", 2)
	%RightClickMenu.add_icon_item(get_theme_icon("ExternalLink", "EditorIcons"), "Open in External Program", 3)

	await get_tree().process_frame
	if DialogicUtil.get_editor_setting("sidebar_collapsed", false):
		_hide_sidebar()


################################################################################
## 						SHOW/HIDE SIDEBAR
################################################################################


func _show_sidebar() -> void:
	%VBoxPrimary.show()
	%VBoxHidden.hide()
	DialogicUtil.set_editor_setting("sidebar_collapsed", false)
	show_sidebar.emit(true)


func _hide_sidebar() -> void:
	%VBoxPrimary.hide()
	%VBoxHidden.show()
	DialogicUtil.set_editor_setting("sidebar_collapsed", true)
	show_sidebar.emit(false)


################################################################################
## 						RESOURCE LIST
################################################################################


func _on_editors_resource_opened(resource: Resource) -> void:
	update_resource_list()
	pass


func _on_editors_editor_changed(previous: DialogicEditor, current: DialogicEditor) -> void:
	%ContentListSection.visible = current.current_resource is DialogicTimeline
	update_resource_list()


func clean_resource_list(resources_list: Array = []) -> PackedStringArray:
	return PackedStringArray(resources_list.filter(func(x): return ResourceLoader.exists(x)))


func update_resource_list(resources_list: PackedStringArray = []) -> void:
	var filter: String = %Search.text
	var current_file := ""
	if editors_manager.current_editor and editors_manager.current_editor.current_resource:
		current_file = editors_manager.current_editor.current_resource.resource_path

	var character_directory: Dictionary = DialogicResourceUtil.get_character_directory()
	var timeline_directory: Dictionary = DialogicResourceUtil.get_timeline_directory()
	if resources_list.is_empty():
		resources_list = DialogicUtil.get_editor_setting("last_resources", [])
		if !current_file in resources_list:
			resources_list.append(current_file)

	resources_list = clean_resource_list(resources_list)

	%CurrentResource.text = "No Resource"
	%CurrentResource.add_theme_color_override(
		"font_uneditable_color", get_theme_color("disabled_font_color", "Editor")
	)

	resource_tree.clear()
	var resource_list_items := []

	var character_items := []
	for character_name in character_directory:
		if character_directory[character_name] in resources_list:
			if filter.is_empty() or filter.to_lower() in character_name.to_lower():
				var item := ResourceListItem.new()
				item.text = character_name
				item.icon = load("res://addons/dialogic/Editor/Images/Resources/character.svg")
				item.metadata = character_directory[character_name]
				item.tooltip = character_directory[character_name]
				character_items.append(item)

	var timeline_items := []
	for timeline_name in timeline_directory:
		if timeline_directory[timeline_name] in resources_list:
			if filter.is_empty() or filter.to_lower() in timeline_name.to_lower():
				var item := ResourceListItem.new()
				item.text = timeline_name
				item.icon = get_theme_icon("TripleBar", "EditorIcons")
				item.metadata = timeline_directory[timeline_name]
				item.tooltip = timeline_directory[timeline_name]
				timeline_items.append(item)

	character_items.sort_custom(_sort_by_item_text)
	timeline_items.sort_custom(_sort_by_item_text)

	# TREE
	var root: TreeItem = resource_tree.create_item()

	if character_items.size() > 0:
		var character_tree = resource_tree.create_item(root)
		character_tree.set_text(0, "Characters")
		character_tree.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
		character_tree.set_custom_bg_color(0, get_theme_color("base_color", "Editor"))
		for item in character_items:
			var character_item = resource_tree.create_item(character_tree)
			character_item.set_text(0, item.text)
			character_item.set_icon(0, item.icon)
			character_item.set_metadata(0, item.metadata)
			character_item.set_tooltip_text(0, item.tooltip)
			if item.metadata == current_file:
				%CurrentResource.text = item.metadata.get_file()
				resource_tree.set_selected(character_item, 0)
	if timeline_items.size() > 0:
		var timeline_tree = resource_tree.create_item(root) as TreeItem
		timeline_tree.set_text(0, "Timelines")
		timeline_tree.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
		timeline_tree.set_custom_bg_color(0, get_theme_color("base_color", "Editor"))
		for item in timeline_items:
			var timeline_item = resource_tree.create_item(timeline_tree) as TreeItem
			timeline_item.set_text(0, item.text)
			timeline_item.set_icon(0, item.icon)
			timeline_item.set_metadata(0, item.metadata)
			timeline_item.set_tooltip_text(0, item.tooltip)
			if item.metadata == current_file:
				%CurrentResource.text = item.metadata.get_file()
				resource_tree.set_selected(timeline_item, 0)

	if %CurrentResource.text != "No Resource":
		%CurrentResource.add_theme_color_override(
			"font_uneditable_color", get_theme_color("font_color", "Editor")
		)
	DialogicUtil.set_editor_setting("last_resources", resources_list)


func _on_resources_tree_item_activated() -> void:
	if resource_tree.get_selected() == null:
		return
	var item := resource_tree.get_selected()
	if item.get_metadata(0) == null:
		return
	editors_manager.edit_resource(load(item.get_metadata(0)))


func _on_resources_tree_item_clicked(_pos: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		return
	if mouse_button_index == MOUSE_BUTTON_MIDDLE:
		remove_item_from_list(resource_tree.get_selected())
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		%RightClickMenu.popup_on_parent(Rect2(get_global_mouse_position(), Vector2()))
		(%RightClickMenu as PopupMenu).set_meta("item_clicked", resource_tree.get_selected())


func _on_search_text_changed(new_text: String) -> void:
	update_resource_list()
	var tree_root := resource_tree.get_root()
	var tree_items := tree_root.get_children()
	if tree_items.size() == 0:
		return
	for item in tree_items:
		if item.get_children().size() > 0:
			resource_tree.set_selected(item.get_child(0), 0)
			break


func _on_search_text_submitted(new_text: String) -> void:
	if resource_tree.get_selected() == null:
		return
	var item := resource_tree.get_selected()
	if item.get_metadata(0) == null:
		return
	editors_manager.edit_resource(load(item.get_metadata(0)))
	%Search.clear()


func set_unsaved_indicator(saved: bool = true) -> void:
	if saved and %CurrentResource.text.ends_with("(*)"):
		%CurrentResource.text = %CurrentResource.text.trim_suffix("(*)")
	if not saved and not %CurrentResource.text.ends_with("(*)"):
		%CurrentResource.text = %CurrentResource.text + "(*)"


func _on_logo_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		editors_manager.open_editor(editors_manager.editors["HomePage"].node)


func update_content_list(list: PackedStringArray) -> void:
	var prev_selected := ""
	if %ContentList.is_anything_selected():
		prev_selected = %ContentList.get_item_text(%ContentList.get_selected_items()[0])
	%ContentList.clear()
	%ContentList.add_item("~ Top")
	for i in list:
		if i.is_empty():
			continue
		%ContentList.add_item(i)
		if i == prev_selected:
			%ContentList.select(%ContentList.item_count - 1)
	if list.is_empty():
		return

	var current_resource: Resource = editors_manager.get_current_editor().current_resource

	var timeline_directory := DialogicResourceUtil.get_timeline_directory()
	var label_directory := DialogicResourceUtil.get_label_cache()
	if current_resource != null:
		for i in timeline_directory:
			if timeline_directory[i] == current_resource.resource_path:
				label_directory[i] = list

	# also always store the current timelines labels for easy access
	label_directory[""] = list

	DialogicResourceUtil.set_label_cache(label_directory)


func remove_item_from_list(item:TreeItem) -> void:
	var new_list := []
	for entry in DialogicUtil.get_editor_setting("last_resources", []):
		if entry != item.get_metadata(0):
			new_list.append(entry)
	DialogicUtil.set_editor_setting("last_resources", new_list)
	update_resource_list(new_list)


func _on_right_click_menu_id_pressed(id: int) -> void:
	match id:
		1:  # REMOVE ITEM FROM LIST
			remove_item_from_list(%RightClickMenu.get_meta("item_clicked"))
		2:  # OPEN IN FILESYSTEM
			EditorInterface.get_file_system_dock().navigate_to_path(
				%RightClickMenu.get_meta("item_clicked").get_metadata(0)
			)
		3:  # OPEN IN EXTERNAL EDITOR
			OS.shell_open(
				ProjectSettings.globalize_path(
					%RightClickMenu.get_meta("item_clicked").get_metadata(0)
				)
			)
		4:  # COPY IDENTIFIER
			DisplayServer.clipboard_set(
				DialogicResourceUtil.get_unique_identifier(
					%RightClickMenu.get_meta("item_clicked").get_metadata(0)
				)
			)


func _sort_by_item_text(a: ResourceListItem, b: ResourceListItem) -> bool:
	return a.text < b.text


class ResourceListItem:
	extends Object
	var text: String
	var index: int = -1
	var icon: Texture
	var metadata: String
	var tooltip: String


	func add_to_item_list(item_list: ItemList, current_file: String) -> void:
		item_list.add_item(text, icon)
		item_list.set_item_metadata(item_list.item_count - 1, metadata)
		item_list.set_item_tooltip(item_list.item_count - 1, tooltip)


	func current_file(sidebar: Control, resource_list: ItemList, current_file: String) -> void:
		if metadata == current_file:
			resource_list.select(index)
			resource_list.set_item_custom_fg_color(
				index, resource_list.get_theme_color("accent_color", "Editor")
			)
			sidebar.find_child("CurrentResource").text = metadata.get_file()
