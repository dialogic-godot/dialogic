@tool
extends Tree

## Tree that displays the portrait list as a hirarchy

var editor = find_parent('Character Editor')
var current_group_nodes := {}


func _ready() -> void:
	$PortraitRightClickMenu.set_item_icon(0, get_theme_icon('Rename', 'EditorIcons'))
	$PortraitRightClickMenu.set_item_icon(1, get_theme_icon('Duplicate', 'EditorIcons'))
	$PortraitRightClickMenu.set_item_icon(2, get_theme_icon('Remove', 'EditorIcons'))


func clear_tree() -> void:
	clear()
	current_group_nodes = {}


func add_portrait_item(portrait_name:String, portrait_data:Dictionary, parent_item:TreeItem, previous_name:String = "") -> TreeItem:
	var item :TreeItem = %PortraitTree.create_item(parent_item)
	item.set_text(0, portrait_name)
	item.set_metadata(0, portrait_data)
	if previous_name.is_empty():
		item.set_meta('previous_name', get_full_item_name(item))
	else:
		item.set_meta('previous_name', previous_name)
	if portrait_name == editor.current_resource.default_portrait:
		item.add_button(0, get_theme_icon('Favorites', 'EditorIcons'), 2, true, 'Default')
	return item


func add_portrait_group(goup_name:String = "Group", parent_item:TreeItem = get_root(), previous_name:String = "") -> TreeItem:
	var item :TreeItem = %PortraitTree.create_item(parent_item)
	item.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
	item.set_text(0, goup_name)
	item.set_metadata(0, {'group':true})
	if previous_name.is_empty():
		item.set_meta('previous_name', get_full_item_name(item))
	else:
		item.set_meta('previous_name', previous_name)
	return item


func get_full_item_name(item:TreeItem) -> String:
	var item_name := item.get_text(0)
	while item.get_parent() != get_root() and item != get_root():
		item_name = item.get_parent().get_text(0)+"/"+item_name
		item = item.get_parent()
	return item_name


# Will create all not yet existing folders in the given path.
# Returns the last folder (the parent of the portrait item of this path). 
func create_necessary_group_items(path:String) -> TreeItem:
	var last_item := get_root()
	var item_path := ""
	
	for i in Array(path.split('/')).slice(0, -1):
		item_path += "/"+i
		item_path = item_path.trim_prefix('/')
		if current_group_nodes.has(item_path+"/"+i):
			last_item = current_group_nodes[item_path+"/"+i]
		else:
			var new_item:TreeItem = add_portrait_group(i, last_item)
			current_group_nodes[item_path+"/"+i] = new_item
			last_item = new_item
	return last_item


func _on_item_mouse_selected(pos:Vector2, mouse_button_index:int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		$PortraitRightClickMenu.set_item_disabled(1, get_selected().get_metadata(0).has('group'))
		$PortraitRightClickMenu.popup_on_parent(Rect2(get_global_mouse_position(),Vector2()))


################################################################################
##					DRAG AND DROP
################################################################################

func _get_drag_data(position:Vector2) -> Variant:
	drop_mode_flags = DROP_MODE_INBETWEEN
	var preview := Label.new()
	preview.text = "     "+get_selected().get_text(0)
	preview.add_theme_stylebox_override('normal', get_theme_stylebox("Background", "EditorStyles"))
	set_drag_preview(preview)
	
	return get_selected()


func _can_drop_data(position:Vector2, data:Variant) -> bool:
	return data is TreeItem


func _drop_data(position:Vector2, item:Variant) -> void:
	var to_item := get_item_at_position(position)
	if to_item:
		var test_item:= to_item
		while true:
			if test_item == item:
				return
			test_item = test_item.get_parent()
			if test_item == get_root():
				break
	
	var drop_section := get_drop_section_at_position(position)
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


func copy_branch_or_item(item:TreeItem, new_parent:TreeItem) -> TreeItem:
	var new_item :TreeItem = null
	if item.get_metadata(0).has('group'):
		new_item = add_portrait_group(item.get_text(0), new_parent, item.get_meta('previous_name'))
	else:
		new_item = add_portrait_item(item.get_text(0), item.get_metadata(0), new_parent, item.get_meta('previous_name'))
	
	for child in item.get_children():
		copy_branch_or_item(child, new_item)
	return new_item

