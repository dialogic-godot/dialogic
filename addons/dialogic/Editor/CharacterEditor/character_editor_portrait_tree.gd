@tool
extends Tree

## Tree that displays the portrait list as a hirarchy

var editor := find_parent('Character Editor')
var current_group_nodes := {}


func _ready() -> void:
	if owner.get_parent() is SubViewport:
		return
	$PortraitRightClickMenu.set_item_icon(0, get_theme_icon('Rename', 'EditorIcons'))
	$PortraitRightClickMenu.set_item_icon(1, get_theme_icon('Duplicate', 'EditorIcons'))
	$PortraitRightClickMenu.set_item_icon(2, get_theme_icon('Remove', 'EditorIcons'))
	$PortraitRightClickMenu.set_item_icon(4, get_theme_icon("Favorites", "EditorIcons"))


func clear_tree() -> void:
	clear()
	update_left_item_margin(false)
	current_group_nodes = {}


func add_portrait_item(portrait_name: String, portrait_data: Dictionary, parent_item: TreeItem, previous_name := "") -> TreeItem:
	var item: TreeItem = %PortraitTree.create_item(parent_item)
	item.set_text(0, portrait_name)
	item.set_metadata(0, portrait_data)
	if previous_name.is_empty():
		item.set_meta('previous_name', get_full_item_name(item))
	else:
		item.set_meta('previous_name', previous_name)
	if portrait_name == editor.current_resource.default_portrait:
		item.add_button(0, get_theme_icon('Favorites', 'EditorIcons'), 2, true, 'Default')
	return item


func add_portrait_group(goup_name := "Group", parent_item: TreeItem = get_root(), previous_name := "") -> TreeItem:
	var item: TreeItem = %PortraitTree.create_item(parent_item)
	item.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
	item.set_text(0, goup_name)
	item.set_metadata(0, {'group':true})
	if previous_name.is_empty():
		item.set_meta('previous_name', get_full_item_name(item))
	else:
		item.set_meta('previous_name', previous_name)
	update_left_item_margin(true)
	return item


func get_full_item_name(item: TreeItem) -> String:
	var item_name := item.get_text(0)
	while item.get_parent() != get_root() and item != get_root():
		item_name = item.get_parent().get_text(0)+"/"+item_name
		item = item.get_parent()
	return item_name


## Will create all not yet existing folders in the given path.
## Returns the last folder (the parent of the portrait item of this path).
func create_necessary_group_items(path: String) -> TreeItem:
	var last_item := get_root()
	var item_path := ""

	for i in Array(path.split('/')).slice(0, -1):
		item_path += "/"+i
		item_path = item_path.trim_prefix('/')
		if current_group_nodes.has(item_path+"/"+i):
			last_item = current_group_nodes[item_path+"/"+i]
		else:
			var new_item: TreeItem = add_portrait_group(i, last_item)
			current_group_nodes[item_path+"/"+i] = new_item
			last_item = new_item
	return last_item


func _on_item_mouse_selected(pos: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		$PortraitRightClickMenu.set_item_disabled(1, get_selected().get_metadata(0).has('group'))
		$PortraitRightClickMenu.popup_on_parent(Rect2(get_global_mouse_position(),Vector2()))


func update_left_item_margin(margin_on:bool) -> void:
	if not margin_on:
		add_theme_constant_override("item_margin", 0)
	else:
		remove_theme_constant_override("item_margin")



#region DRAG AND DROP
################################################################################

func _get_drag_data(at_position: Vector2) -> Variant:
	var drag_item := get_item_at_position(at_position)
	if not drag_item:
		return null

	drop_mode_flags = DROP_MODE_INBETWEEN
	var preview := Label.new()
	preview.text = "     "+drag_item.get_text(0)
	preview.add_theme_stylebox_override('normal', get_theme_stylebox("Background", "EditorStyles"))
	set_drag_preview(preview)

	return drag_item


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and 'files' in data.keys():
		return true
	return data is TreeItem


func _drop_data(at_position: Vector2, item: Variant) -> void:
	if item is Dictionary:
		owner.import_portraits_from_file_list(item.files)
		return

	var to_item := get_item_at_position(at_position)
	if to_item:
		var test_item := to_item
		while true:
			if test_item == item:
				return
			test_item = test_item.get_parent()
			if test_item == get_root():
				break

	var drop_section := get_drop_section_at_position(at_position)
	var parent := get_root()
	if to_item:
		parent = to_item.get_parent()

	if to_item and to_item.get_metadata(0).has('group') and drop_section == 1:
		parent = to_item

	var new_item := copy_branch_or_item(item, parent)

	if to_item and !to_item.get_metadata(0).has('group') and drop_section == 1:
		new_item.move_after(to_item)

	if drop_section == -1:
		new_item.move_before(to_item)

	editor.report_name_change(new_item)

	item.free()


func copy_branch_or_item(item: TreeItem, new_parent: TreeItem) -> TreeItem:
	var new_item: TreeItem = null
	if item.get_metadata(0).has('group'):
		new_item = add_portrait_group(item.get_text(0), new_parent, item.get_meta('previous_name'))
	else:
		new_item = add_portrait_item(item.get_text(0), item.get_metadata(0), new_parent, item.get_meta('previous_name'))

	for child in item.get_children():
		copy_branch_or_item(child, new_item)
	return new_item

#endregion
