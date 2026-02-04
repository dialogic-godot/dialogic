@tool
extends Tree

enum Buttons {DELETE, SELECT}

var loading := false
signal changed


func _ready() -> void:
	set_column_title(0, "Properties")
	set_column_expand_ratio(0, 2)
	set_column_title(1, "Name")
	#set_column_expand_ratio(1, 0.5)
	set_column_title(2, "Tooltip")
	set_column_expand(3, false)
	set_column_custom_minimum_width(3, 50)
	set_column_clip_content(3, true)
	#set_column_expand_ratio(2, 0.5)


func load_data(data:Array, scene_root:Node) -> void:
	loading = true
	clear()
	create_item()
	var current_category : TreeItem  = null
	#var current_group : TreeItem = null
	var current_node : TreeItem = null

	for i in data:
		match i.type:
			"Category":
				current_category = add_category_item(i.name)
			"Node":
				current_node = add_node_item(current_category, i.name, i.display_name)
			"Property":
				add_property_item(current_node, i.name, i.display_name, i.tooltip)
	loading = false

func get_data(item:TreeItem = null, data:Array[Dictionary] = []) -> Array[Dictionary]:
	if item == null:
		item = get_root()
	for child in item.get_children():
		data.append({
			"name":child.get_text(0),
			"display_name":child.get_text(1),
			"type":child.get_metadata(0).type,
			"tooltip":child.get_text(2)})
		if child.get_child_count():
			data = get_data(child, data)
	return data


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	drop_mode_flags = DROP_MODE_INBETWEEN
	if data is Dictionary:
		if data.get("type", "") == "nodes":
			return true
		if data.get("type", "") == "obj_property":
			return true
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data is Dictionary:
		if data.get("type", "") == "nodes":
			var item_at_pos := get_item_at_position(at_position)
			var parent : TreeItem
			if item_at_pos:
				parent = item_at_pos
				while parent != get_root() and parent.get_metadata(0).type != "Category":
					parent = parent.get_parent()
			for node_path in data.get("nodes", []):
				if not get_node_item(get_node(node_path)):
					add_node_item(parent, get_node_path(get_node(node_path)))
		if data.get("type", "") == "obj_property":
			var item_at_pos := get_item_at_position(at_position)
			var node_item := get_node_item(data.get("object"))
			if not node_item:
				var parent : TreeItem
				if item_at_pos:
					parent = item_at_pos
					while parent != get_root() and parent.get_metadata(0).type != "Category":
						parent = parent.get_parent()
				node_item = add_node_item(parent, get_node_path(data.get("object")))

			if item_at_pos == node_item.get_parent():
				if item_at_pos.get_child_count() > 1:
					node_item.move_before(item_at_pos.get_child(0))
			var property_item := add_property_item(node_item, data.get("property"))
			if not item_at_pos:
				return

			if item_at_pos == node_item:
				if node_item.get_child_count() > 1:
					property_item.move_before(node_item.get_child(0))

			if item_at_pos.get_parent() == node_item:
				var drop_section := get_drop_section_at_position(at_position)
				if drop_section == -1:
					property_item.move_before(item_at_pos)
				else:
					property_item.move_after(item_at_pos)
			EditorInterface.get_inspector().edit(EditorInterface.get_inspector().get_edited_object())


func get_node_item(node:Node, parent:TreeItem = null) -> TreeItem:
	if parent == null: parent = get_root()
	for item in parent.get_children():
		if item.get_metadata(0).type == "Node":
			if get_scene_node(item.get_metadata(0).node_path) == node:
				return item
		if item.get_metadata(0).type == "Category":
			var result := get_node_item(node, item)
			if result: return result
	return null


func add_data_item_indexed(parent:TreeItem, data:Dictionary, index:=0) -> void:
	match data.type:
		"Category":
			add_category_item(data.name)
		"Node":
			add_node_item(parent, data.name, data.display_name)
		"Property":
			add_property_item(parent, data.name, data.display_name, data.tooltip)


func add_category_item(category_name:String = "") -> TreeItem:
	var item := create_item()
	item.set_text(0, category_name)
	item.set_editable(0, true)
	item.set_custom_bg_color(0, get_theme_color("disabled_highlight_color", "Editor"))
	item.set_custom_bg_color(1, get_theme_color("disabled_highlight_color", "Editor"))
	item.set_custom_bg_color(2, get_theme_color("disabled_highlight_color", "Editor"))
	item.add_button(3, get_theme_icon("Remove", "EditorIcons"), Buttons.DELETE, false, "Delete All Node Customization")
	item.set_metadata(0, {"type":"Category"})
	item.set_cell_mode(3, TreeItem.CELL_MODE_CUSTOM)
	if category_name.is_empty():
		get_tree().process_frame.connect(func(): item.select(0); edit_selected(), CONNECT_ONE_SHOT)
	if not loading:
		changed.emit()
	return item





func add_node_item(parent:TreeItem, node_path:String = "", node_display_name := "") -> TreeItem:
	var item := create_item(parent)
	#if owner.scene_root.get_node(node_path)
	item.set_text(0, node_path)
	item.set_text(1, node_display_name if node_display_name else node_path)
	item.set_editable(0, true)
	item.set_editable(1, true)
	item.set_editable(2, true)
	item.set_custom_bg_color(0, get_theme_color("highlight_color", "Editor"))
	item.set_custom_bg_color(1, get_theme_color("highlight_color", "Editor"))
	item.set_custom_bg_color(2, get_theme_color("highlight_color", "Editor"))
	item.add_button(3, get_theme_icon("ToolSelect", "EditorIcons"), Buttons.SELECT, false, "Select")
	item.add_button(3, get_theme_icon("Remove", "EditorIcons"), Buttons.DELETE, false, "Delete All Node Customization")
	item.set_metadata(0, {"type":"Node", "node_path":node_path})
	item.set_cell_mode(3, TreeItem.CELL_MODE_CUSTOM)
	if not loading:
		changed.emit()
	return item


func get_node_path(node:Node) -> String:
	var node_path: NodePath = owner.scene_root.get_path_to(node , true)
	if node.unique_name_in_owner:
		node_path = "%"+node.name
	return node_path


func get_scene_node(node_path:String) -> Node:
	return owner.scene_root.get_node(node_path)

func add_property_item(parent:TreeItem, property_path:String, property_name := "", tooltip := "") -> TreeItem:
	var item := create_item(parent)

	if property_name.is_empty():
		property_name = simplify_name(property_path)

	item.set_text(0, property_path)
	item.set_text(1, property_name)
	item.set_text(2, tooltip)
	item.set_editable(0, true)
	item.set_editable(1, true)
	item.set_editable(2, true)
	item.add_button(3, get_theme_icon("Remove", "EditorIcons"), Buttons.DELETE, false, "Delete This Property Customization")
	item.set_metadata(0, {"type":"Property"})
	item.set_cell_mode(3, TreeItem.CELL_MODE_CUSTOM)
	if not loading:
		changed.emit()
	return item


func _on_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	match id:
		Buttons.DELETE:
			item.free()
			changed.emit()
		Buttons.SELECT:
			var node := get_scene_node(item.get_metadata(0).node_path)
			EditorInterface.get_inspector().edit(node)
			EditorInterface.get_selection().clear()
			EditorInterface.get_selection().add_node(node)


func simplify_name(property_path:String) -> String:
	property_path = property_path.replace("theme_override_", "")
	property_path = property_path.capitalize()
	return property_path


func _on_column_title_clicked(column: int, _mouse_button_index: int) -> void:
	if column == 3:
		return
	var column_collapsed := is_column_clipping_content(column)
	set_column_clip_content(column, not column_collapsed)
	set_column_expand(column, column_collapsed)
	set_column_custom_minimum_width(column, 0 if column_collapsed else 20)


func _on_item_edited() -> void:
	changed.emit()
