@tool
class_name DialogicSidebar extends Control

## Script that handles the editor sidebar.

signal content_item_activated(item_name)
signal show_sidebar(show: bool)

# References
@onready var editors_manager = get_parent().get_parent()
@onready var resource_tree: Tree = %ResourceTree

var current_resource_list: Array = []

enum GroupMode {
	NONE,
	TYPE,
	FOLDER,
	PATH,
}
var group_mode: GroupMode = GroupMode.TYPE


func _ready() -> void:
	if owner != null and owner.get_parent() is SubViewport:
		return
	if editors_manager is SubViewportContainer:
		return

	## CONNECTIONS
	editors_manager.resource_opened.connect(_on_editors_resource_opened)
	editors_manager.editor_changed.connect(_on_editors_editor_changed)

	resource_tree.item_activated.connect(_on_resources_tree_item_activated)
	resource_tree.item_mouse_selected.connect(_on_resources_tree_item_clicked)
	resource_tree.item_collapsed.connect(_on_resources_tree_item_collapsed)

	%ContentList.item_selected.connect(
		func(idx: int): content_item_activated.emit(%ContentList.get_item_text(idx))
	)

	%OpenButton.pressed.connect(_show_sidebar)
	%CloseButton.pressed.connect(_hide_sidebar)

	var editor_scale := DialogicUtil.get_editor_scale()

	## ICONS
	%Logo.texture = load("res://addons/dialogic/Editor/Images/dialogic-logo.svg")
	%Logo.custom_minimum_size.y = 30 * editor_scale
	%Search.right_icon = get_theme_icon("Search", "EditorIcons")
	%Options.icon = get_theme_icon("GuiTabMenuHl", "EditorIcons")
	%OptionsPanel.add_theme_stylebox_override("panel", get_theme_stylebox("PanelForeground", "EditorStyles"))
	%OptionsPopup.hide()

	%ContentList.add_theme_color_override(
		"font_hovered_color", get_theme_color("warning_color", "Editor")
	)
	%ContentList.add_theme_color_override(
		"font_selected_color", get_theme_color("property_color_z", "Editor")
	)

	## RIGHT CLICK MENU
	%RightClickMenu.clear()
	%RightClickMenu.add_icon_item(get_theme_icon("Remove", "EditorIcons"), "Remove From List", 1)
	%RightClickMenu.add_separator()
	%RightClickMenu.add_icon_item(get_theme_icon("ActionCopy", "EditorIcons"), "Copy Identifier", 4)
	%RightClickMenu.add_separator()
	%RightClickMenu.add_icon_item(
		get_theme_icon("Filesystem", "EditorIcons"), "Show in FileSystem", 2
	)
	%RightClickMenu.add_icon_item(
		get_theme_icon("ExternalLink", "EditorIcons"), "Open in External Program", 3
	)

	## SORT MENU
	%GroupingOptions.set_item_icon(0, get_theme_icon("AnimationTrackGroup", "EditorIcons"))
	%GroupingOptions.set_item_icon(1, get_theme_icon("Folder", "EditorIcons"))
	%GroupingOptions.set_item_icon(2, get_theme_icon("FolderBrowse", "EditorIcons"))
	%GroupingOptions.set_item_icon(3, get_theme_icon("AnimationTrackList", "EditorIcons"))
	%GroupingOptions.item_selected.connect(_on_grouping_changed)

	await get_tree().process_frame
	if DialogicUtil.get_editor_setting("sidebar_collapsed", false):
		_hide_sidebar()

	%MainVSplit.split_offset = DialogicUtil.get_editor_setting("sidebar_v_split", 0)
	group_mode = DialogicUtil.get_editor_setting("sidebar_group_mode", 0)
	%GroupingOptions.select(%GroupingOptions.get_item_index(group_mode))

	%FolderColors.button_pressed = DialogicUtil.get_editor_setting("sidebar_use_folder_colors", true)
	%TrimFolderPaths.button_pressed = DialogicUtil.get_editor_setting("sidebar_trim_folder_paths", true)

	update_resource_list()


func set_unsaved_indicator(saved: bool = true) -> void:
	if saved and %CurrentResource.text.ends_with("(*)"):
		%CurrentResource.text = %CurrentResource.text.trim_suffix("(*)")
	if not saved and not %CurrentResource.text.ends_with("(*)"):
		%CurrentResource.text = %CurrentResource.text + "(*)"


func _on_logo_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		editors_manager.open_editor(editors_manager.editors["HomePage"].node)


#region SHOW/HIDE SIDEBAR
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

#endregion


################################################################################
## 						RESOURCE LIST
################################################################################


func _on_editors_resource_opened(_resource: Resource) -> void:
	update_resource_list()


func _on_editors_editor_changed(_previous: DialogicEditor, current: DialogicEditor) -> void:
	%ContentListSection.visible = current.current_resource is DialogicTimeline
	update_resource_list()


## Cleans resources that have been deleted from the resource list
func clean_resource_list(resources_list: Array = []) -> PackedStringArray:
	return PackedStringArray(resources_list.filter(func(x): return ResourceLoader.exists(x)))


#region BULDING/FILTERING THE RESOURCE LIST

func update_resource_list(resources_list: PackedStringArray = []) -> void:
	var filter: String = %Search.text
	var current_file := ""
	if editors_manager.current_editor and editors_manager.current_editor.current_resource:
		current_file = editors_manager.current_editor.current_resource.resource_path

	var character_directory: Dictionary = DialogicResourceUtil.get_character_directory()
	var timeline_directory: Dictionary = DialogicResourceUtil.get_timeline_directory()
	if resources_list.is_empty():
		resources_list = DialogicUtil.get_editor_setting("last_resources", [])
		if not current_file in resources_list:
			resources_list.append(current_file)

	resources_list = clean_resource_list(resources_list)

	%CurrentResource.text = "No Resource"
	%CurrentResource.add_theme_color_override(
		"font_uneditable_color", get_theme_color("disabled_font_color", "Editor")
	)

	resource_tree.clear()

	var character_items: Array = get_directory_items.call(character_directory, filter, load("res://addons/dialogic/Editor/Images/Resources/character.svg"), resources_list)
	var timeline_items: Array = get_directory_items.call(timeline_directory, filter, load("res://addons/dialogic/Editor/Images/Resources/timeline.svg"), resources_list)
	var all_items := character_items + timeline_items

	# BUILD TREE
	var root: TreeItem = resource_tree.create_item()

	match group_mode:
		GroupMode.NONE:
			all_items.sort_custom(_sort_by_item_text)
			for item in all_items:
				add_item(item, root, current_file)


		GroupMode.TYPE:
			character_items.sort_custom(_sort_by_item_text)
			timeline_items.sort_custom(_sort_by_item_text)
			if character_items.size() > 0:
				var character_tree := add_folder_item("Characters", root)
				for item in character_items:
					add_item(item, character_tree, current_file)

			if timeline_items.size() > 0:
				var timeline_tree := add_folder_item("Timelines", root)
				for item in timeline_items:
					add_item(item, timeline_tree, current_file)


		GroupMode.FOLDER:
			var dirs := {}
			for item in all_items:
				var dir := item.get_parent_directory() as String
				if not dirs.has(dir):
					dirs[dir] = []
				dirs[dir].append(item)

			for dir in dirs:
				var dir_item := add_folder_item(dir, root)

				for item in dirs[dir]:
					add_item(item, dir_item, current_file)


		GroupMode.PATH:
			# Collect all different directories that contain resources
			var dirs := {}
			for item in all_items:
				var path := (item.metadata.get_base_dir() as String).trim_prefix("res://")
				if not dirs.has(path):
					dirs[path] = []
				dirs[path].append(item)

			# Sort them into ones with the same folder name
			var dir_names := {}
			for dir in dirs:
				var sliced: String = dir.get_slice("/", dir.get_slice_count("/")-1)
				if not sliced in dir_names:
					dir_names[sliced] = {"folders":[dir]}
				else:
					dir_names[sliced].folders.append(dir)

			# Create a dictionary mapping a unique name to each directory
			# If two have been found to have the same folder name, the parent directory is added
			var unique_folder_names := {}
			for dir_name in dir_names:
				if dir_names[dir_name].folders.size() > 1:
					for i in dir_names[dir_name].folders:
						if "/" in i:
							unique_folder_names[i.get_slice("/", i.get_slice_count("/")-2)+"/"+i.get_slice("/", i.get_slice_count("/")-1)] = i
						else:
							unique_folder_names[i] = i
				else:
					unique_folder_names[dir_name] = dir_names[dir_name].folders[0]

			# Sort the folder names by their folder name (not by the full path)
			var sorted_dir_keys := unique_folder_names.keys()
			sorted_dir_keys.sort_custom(
				func(x, y):
					return x.get_slice("/", x.get_slice_count("/")-1) < y.get_slice("/", y.get_slice_count("/")-1)
					)
			var folder_colors: Dictionary = ProjectSettings.get_setting("file_customization/folder_colors", {})

			for dir in sorted_dir_keys:
				var display_name: String = dir
				if not %TrimFolderPaths.button_pressed:
					display_name = unique_folder_names[dir]
				var dir_path: String = unique_folder_names[dir]
				var dir_color_path := ""
				var dir_color := Color.BLACK
				if %FolderColors.button_pressed:
					for path in folder_colors:
						if String("res://"+dir_path+"/").begins_with(path) and len(path) > len(dir_color_path):
							dir_color_path = path
							dir_color = folder_colors[path]

				var dir_item := add_folder_item(display_name, root, dir_color, dir_path)

				for item in dirs[dir_path]:
					add_item(item, dir_item, current_file)


	if %CurrentResource.text != "No Resource":
		%CurrentResource.add_theme_color_override(
			"font_uneditable_color", get_theme_color("font_color", "Editor")
		)

	DialogicUtil.set_editor_setting("last_resources", resources_list)


func add_item(item:ResourceListItem, parent:TreeItem, current_file := "") -> TreeItem:
	var tree_item := resource_tree.create_item(parent)
	tree_item.set_text(0, item.text)
	tree_item.set_icon(0, item.icon)
	tree_item.set_metadata(0, item.metadata)
	tree_item.set_tooltip_text(0, item.tooltip)

	if item.metadata == current_file:
		%CurrentResource.text = item.metadata.get_file()
		resource_tree.set_selected(tree_item, 0)

	var bg_color := parent.get_custom_bg_color(0)
	if bg_color != get_theme_color("base_color", "Editor"):
		bg_color.a = 0.1
		tree_item.set_custom_bg_color(0, bg_color)

	return tree_item


func add_folder_item(label: String, parent:TreeItem, color:= Color.BLACK, tooltip:="") -> TreeItem:
	var folder_item := resource_tree.create_item(parent)
	folder_item.set_text(0, label)
	folder_item.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
	folder_item.set_tooltip_text(0, tooltip)
	if color == Color.BLACK:
		folder_item.set_custom_bg_color(0, get_theme_color("base_color", "Editor"))
	else:
		color.a = 0.2
		folder_item.set_custom_bg_color(0, color)

	if label in DialogicUtil.get_editor_setting("resource_list_collapsed_info", []):
		folder_item.collapsed = true

	return folder_item


func get_directory_items(directory:Dictionary, filter:String, icon:Texture2D, resources_list:Array) -> Array:
	var items := []
	for item_name in directory:
		if (directory[item_name] in resources_list) and (filter.is_empty() or filter.to_lower() in item_name.to_lower()):
			var item := ResourceListItem.new()
			item.text = item_name
			item.icon = icon
			item.metadata = directory[item_name]
			item.tooltip = directory[item_name]
			items.append(item)
	return items


class ResourceListItem:
	extends Object

	var text: String
	var index: int = -1
	var icon: Texture
	var metadata: String
	var tooltip: String

	func _to_string() -> String:
		return JSON.stringify(
			{
				"text": text,
				"index": index,
				"icon": icon.resource_path,
				"metadata": metadata,
				"tooltip": tooltip,
				"parent_dir": get_parent_directory()
			},
			"\t",
			false
		)

	func get_parent_directory() -> String:
		return (metadata.get_base_dir() as String).split("/")[-1]


func _sort_by_item_text(a: ResourceListItem, b: ResourceListItem) -> bool:
	return a.text < b.text

#endregion


#region INTERACTING WITH RESOURCES


func _on_resources_tree_item_activated() -> void:
	if resource_tree.get_selected() == null:
		return
	var item := resource_tree.get_selected()
	if item.get_metadata(0) == null:
		return
	edit_resource(item.get_metadata(0))


func _on_resources_tree_item_clicked(_pos: Vector2, mouse_button_index: int) -> void:
	match mouse_button_index:
		MOUSE_BUTTON_LEFT:
			var selected_item := resource_tree.get_selected()
			if selected_item == null:
				return
			if selected_item.get_metadata(0) == null:
				return
			var resource_item := load(selected_item.get_metadata(0))
			call_deferred("edit_resource", resource_item)

		MOUSE_BUTTON_MIDDLE:
			remove_item_from_list(resource_tree.get_selected())

		MOUSE_BUTTON_RIGHT:
			if resource_tree.get_selected().get_metadata(0):
				%RightClickMenu.popup_on_parent(Rect2(get_global_mouse_position(), Vector2()))
				%RightClickMenu.set_meta("item_clicked", resource_tree.get_selected())


func _on_resources_tree_item_collapsed(item:TreeItem) -> void:
	var collapsed_info: Array = DialogicUtil.get_editor_setting("resource_list_collapsed_info", [])
	if item.get_text(0) in collapsed_info:
		if not item.collapsed:
			collapsed_info.erase(item.get_text(0))
	else:
		if item.collapsed:
			collapsed_info.append(item.get_text(0))
	DialogicUtil.set_editor_setting("resource_list_collapsed_info", collapsed_info)


func edit_resource(resource_item: Variant) -> void:
	if resource_item is Resource:
		editors_manager.edit_resource(resource_item)
	else:
		editors_manager.edit_resource(load(resource_item))


func remove_item_from_list(item: TreeItem) -> void:
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
				DialogicResourceUtil.get_unique_identifier_by_path(
					%RightClickMenu.get_meta("item_clicked").get_metadata(0)
				)
			)
#endregion


#region FILTERING

func _on_search_text_changed(_new_text: String) -> void:
	update_resource_list()
	for item in resource_tree.get_root().get_children():
		if item.get_children().size() > 0:
			resource_tree.set_selected(item.get_child(0), 0)
			break


func _on_search_text_submitted(_new_text: String) -> void:
	if resource_tree.get_selected() == null:
		return
	var item := resource_tree.get_selected()
	if item.get_metadata(0) == null:
		return
	edit_resource(item.get_metadata(0))
	%Search.clear()

#endregion


#region CONTENT LIST

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

#endregion


#region RESOURCE LIST OPTIONS

func _on_options_pressed() -> void:
	%OptionsPopup.popup_on_parent(Rect2(%Options.global_position+%Options.size*Vector2(0,1), Vector2()))


func _on_grouping_changed(idx: int) -> void:
	var id: int = %GroupingOptions.get_item_id(idx)
	if (GroupMode as Dictionary).values().has(id):
		group_mode = (id as GroupMode)
		DialogicUtil.set_editor_setting("sidebar_group_mode", id)
		update_resource_list()
		if id == GroupMode.NONE:
			%ResourceTree.add_theme_constant_override("item_margin", 0)
		else:
			%ResourceTree.remove_theme_constant_override("item_margin")

	%FolderColors.disabled = group_mode != GroupMode.PATH
	%TrimFolderPaths.disabled = group_mode != GroupMode.PATH


func _on_folder_colors_toggled(toggled_on: bool) -> void:
	DialogicUtil.set_editor_setting("sidebar_use_folder_colors", toggled_on)
	update_resource_list()


func _on_trim_folder_paths_toggled(toggled_on: bool) -> void:
	DialogicUtil.set_editor_setting("sidebar_trim_folder_paths", toggled_on)
	update_resource_list()

#endregion


func _on_main_v_split_dragged(offset: int) -> void:
	DialogicUtil.set_editor_setting("sidebar_v_split", offset)
