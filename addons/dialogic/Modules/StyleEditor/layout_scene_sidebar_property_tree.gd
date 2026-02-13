@tool
extends Tree

enum Buttons {DELETE, SELECT}

var loading := false
signal changed


func _ready() -> void:
	if owner.get_parent() is SubViewport:
		return

	set_column_title(0, "Properties")
	set_column_expand_ratio(0, 2)
	set_column_title(1, "Name")
	#set_column_expand_ratio(1, 0.5)
	set_column_title(2, "Tooltip")
	set_column_expand(3, false)
	set_column_custom_minimum_width(3, 50)
	set_column_clip_content(3, true)
	#set_column_expand_ratio(2, 0.5)

	%InfoLabel.add_theme_color_override("font_color", get_theme_color("font_readonly_color", "Editor"))


func load_data(data:Array) -> void:
	loading = true
	clear()
	create_item()
	var current_category : TreeItem  = null
	#var current_group : TreeItem = null
	var current_node : TreeItem = null

	for i in data:
		match i.type:
			"Category":
				current_category = add_category_item(i)
			"Node":
				current_node = add_node_item(current_category, i)
			"Property":
				add_property_item(current_node, i)

	%InfoLabel.visible = get_root().get_child_count() == 0
	loading = false


func get_data() -> Array[Dictionary]:
	var current_data: Array[Dictionary] = []
	var item := get_root()
	while item:
		if item.get_metadata(0):
			current_data.append({
				"name":item.get_text(0),
				"display_name":item.get_text(1),
				"type":item.get_metadata(0).type,
				"tooltip":item.get_text(2)})
			if item.collapsed:
				current_data[-1]["collapsed"] = true
		item = item.get_next_in_tree()
	return current_data


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data is TreeItem:
		var drop_at := get_item_at_position(at_position)
		var drop_section := get_drop_section_at_position(at_position)
		drop_mode_flags = DROP_MODE_INBETWEEN
		match data.get_metadata(0).type:
			"Category":
				if not drop_at:
					return true
				if drop_at.get_metadata(0).type == "Category":
					if drop_section == -1 or drop_at.collapsed:
						return true
			"Node":
				if not drop_at:
					return true
				if drop_at.get_metadata(0).type == "Category":
					if drop_section == -1 and drop_at.get_index() == 0:
						return false
					return true
				elif drop_at.get_metadata(0).type == "Node":
					if drop_section == -1 or drop_at.collapsed:
						return true
				elif drop_at.get_metadata(0).type == "Property":
					if drop_section == 1 and drop_at.get_index() == drop_at.get_parent().get_child_count()-1:
						return true
			"Property":
				return true
				#if not drop_at:
					#return true
				#if drop_at.get_metadata(0).type == "Category":
					#if drop_section == -1 and drop_at.get_index() == 0:
						#return false
					#return true
				#elif drop_at.get_metadata(0).type == "Node":
					#if drop_section == -1 or drop_at.collapsed or drop_at.get_text(0) == data.get_parent().get_text(0):
						#return true
				#elif drop_at.get_metadata(0).type == "Property":
					#if drop_section == 1 and drop_at.get_index() == drop_at.get_parent().get_child_count()-1:
						#return true
					#elif drop_at.get_parent().get_text(0) == data.get_parent().get_text(0):
						#return true

	if data is Dictionary:
		if data.get("type", "") == "obj_property":
			var obj := (data.get("object") as Node)
			if data.get("object").get_class() == "MultiNodeEdit":
				var nodes := EditorInterface.get_selection().get_selected_nodes()
				var n := nodes[0].get_parent()
				if nodes.any(func(x): return x.get_parent() != n):
					return false
				obj = nodes[0]
				## TODO force multi-node property in this case
			if not obj:
				return false

			%DropInfoLabel.visible = is_valid_multi_node_property(obj, data.get("property"))
			%AddCategory.visible = not %DropInfoLabel.visible
			drop_mode_flags = DROP_MODE_INBETWEEN
			return true

	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	%DropInfoLabel.hide()
	%AddCategory.show()

	if data is TreeItem:
		move_item(data, at_position)
		return

	if not data is Dictionary:
		return

	## We do this so changed is only emmitted once the property item has been added
	loading = true

	## Dropping a property dragged from the inspector
	var at_item := get_item_at_position(at_position)
	var drop_section := get_drop_section_at_position(at_position)

	## Just in case not even a category exists, add one
	if at_item == null and get_root().get_child_count() == 0:
		add_category_item({"name":"General"})


	if data.get("type", "") == "obj_property":
		var node_path := get_scene_node_path(
			data.get("object"), is_valid_multi_node_property(data.get("object"), data.get("property")) and Input.is_key_pressed(KEY_CTRL)
			)

		var node_parent_item := find_target_move_node_item(at_position, node_path)
		var property_item := add_property_item(node_parent_item, {"name":data.get("property")})

		if at_item:
			if at_item.get_parent() == node_parent_item:
				if drop_section == -1:
					property_item.move_before(at_item)
				else:
					property_item.move_after(at_item)
			elif at_item == node_parent_item:
				property_item.move_before(at_item.get_child(0))

		property_item.uncollapse_tree()

		changed.emit()

	loading = false


func _get_drag_data(at_position:Vector2) -> Variant:
	var item := get_item_at_position(at_position)
	if item:
		var label := Label.new()
		label.text = item.get_metadata(0).type +": "+item.get_text(0)
		label.add_theme_stylebox_override("normal", get_theme_stylebox("normal", "LineEdit"))
		set_drag_preview(label)
		return item
	return null


func move_item(item:TreeItem, at_position:Vector2):
	var at_item := get_item_at_position(at_position)
	var drop_section := get_drop_section_at_position(at_position)

	if at_item == item:
		return
	loading = true
	match item.get_metadata(0).type:
		"Category":
			if not at_item:
				item.move_after(get_root().get_child(-1))

			elif at_item.get_metadata(0).type == "Category":
				if drop_section == -1:
					item.move_before(at_item)
				else:
					item.move_after(at_item)
		"Node":
			item.get_parent().remove_child(item)
			if not at_item:
				get_root().get_child(-1).add_child(item)

			elif at_item.get_metadata(0).type == "Category":
				if drop_section == -1:
					at_item.get_prev().add_child(item)
				else:
					at_item.add_child(item)
					item.move_before(at_item.get_child(0))
			elif at_item.get_metadata(0).type == "Node":
				at_item.get_parent().add_child(item)
				if drop_section == -1:
					item.move_before(at_item)
				else:
					item.move_after(at_item)
			elif at_item.get_metadata(0).type == "Property":
				at_item.get_parent().get_parent().add_child(item)
				item.move_after(at_item.get_parent().get_parent())

			var col := item.collapsed
			item.uncollapse_tree()
			item.collapsed = col
		"Property":
			var node_parent_item := find_target_move_node_item(at_position, item.get_parent().get_text(0))
			item.get_parent().remove_child(item)
			node_parent_item.add_child(item)
			if at_item:
				if at_item.get_parent() == node_parent_item:
					if drop_section == -1:
						item.move_before(at_item)
					else:
						item.move_after(at_item)
				elif at_item == node_parent_item:
					item.move_before(at_item.get_child(0))

			item.uncollapse_tree()

	loading = false
	changed.emit()


## Returns an existing or new node item for the given path at_position or as close to it as possible.
func find_target_move_node_item(at_position:Vector2, node_path:String) -> TreeItem:
	var at_item := get_item_at_position(at_position)
	var drop_section := get_drop_section_at_position(at_position)

	if not at_item:
		if get_root().get_child(-1).get_child_count() and get_root().get_child(-1).get_child(-1).get_text(0) == node_path:
			return get_root().get_child(-1).get_child(-1)
		else:
			return add_node_item(get_root().get_child(-1), {"name":node_path})

	var drop_at_type: String = at_item.get_metadata(0).type

	if drop_at_type == "Category":
		if drop_section != -1 or at_item.get_index() == 0:
			if at_item.get_child_count() and at_item.get_child(0).get_text(0) == node_path:
				return at_item.get_child(0)
			else:
				var new_node_item := add_node_item(at_item, {"name":node_path})
				new_node_item.move_before(at_item.get_child(0))
				return new_node_item
		elif at_item.get_prev():
			if at_item.get_prev().get_child_count() and at_item.get_prev().get_child(-1).get_text(0) == node_path:
				return at_item.get_prev().get_child(-1)
			else:
				return add_node_item(at_item.get_prev(), {"name":node_path})

	elif drop_at_type == "Node":
		if drop_section != -1 or at_item.get_index() == 0:
			if at_item.get_text(0) == node_path:
				return at_item
			else:
				var new_node_item := add_node_item(at_item.get_parent(), {"name":node_path})
				new_node_item.move_after(at_item)
				return new_node_item
		elif at_item.get_prev() and at_item.get_prev().get_text(0) == node_path:
			return at_item.get_prev()
		else:
			var new_node_item := add_node_item(at_item.get_parent(), {"name":node_path})
			new_node_item.move_before(at_item)
			return new_node_item

	elif drop_at_type == "Property":
		if at_item.get_parent().get_text(0) == node_path:
			return at_item.get_parent()
		else:
			var new_node_item := add_node_item(at_item.get_parent(), {"name":node_path})
			new_node_item.move_after(at_item.get_parent())
			return new_node_item

	return null


## Returns true if all siblings of the given node also have the given property.
func is_valid_multi_node_property(node:Node, property:String) -> bool:
	if node.get_parent().get_child_count() > 1:
		for sibling in node.get_parent().get_children():
			if not property in sibling:
				return false
	else:
		return false
	return true

#
#func get_node_item(node:Node, parent:TreeItem = null) -> TreeItem:
	#if parent == null: parent = get_root()
	#for item in parent.get_children():
		#if item.get_metadata(0).type == "Node":
			#if get_scene_node(item.get_metadata(0).node_path) == node:
				#return item
		#if item.get_metadata(0).type == "Category":
			#var result := get_node_item(node, item)
			#if result: return result
	#return null


func get_scene_node_path(node:Node, multi_node := false) -> String:
	if multi_node: node = node.get_parent()
	var node_path: NodePath = owner.scene_root.get_path_to(node , true)
	if node.unique_name_in_owner:
		node_path = "%"+node.name
	if multi_node:
		node_path = str(node_path) + "/@all_children"
	return node_path


func get_scene_node(node_path:String) -> Node:
	if node_path.ends_with("/@all_children"):
		return owner.scene_root.get_node(node_path.trim_suffix("/@all_children")).get_child(0)
	return owner.scene_root.get_node(node_path)


func get_item_scene_node(item:TreeItem) -> Node:
	return get_scene_node(item.get_metadata(0).get("node_path"))


func add_category_item(data := {}) -> TreeItem:
	var item := create_item()

	item.set_text(0, data.get("name", ""))
	item.set_custom_font(0, get_theme_font("bold", "EditorFonts"))
	item.set_editable(0, true)

	item.set_custom_bg_color(0, get_theme_color("disabled_highlight_color", "Editor"))
	item.set_custom_bg_color(1, get_theme_color("disabled_highlight_color", "Editor"))
	item.set_custom_bg_color(2, get_theme_color("disabled_highlight_color", "Editor"))

	item.add_button(3, get_theme_icon("Remove", "EditorIcons"), Buttons.DELETE, false, "Delete All Node Customization")
	item.set_metadata(0, {"type":"Category"})
	item.set_cell_mode(3, TreeItem.CELL_MODE_CUSTOM)

	item.collapsed = data.get("collapsed", false)

	if data.get("name", "").is_empty():
		get_tree().process_frame.connect(func():
			if not item:
				return;
			await get_tree().process_frame
			item.select(0); edit_selected(), CONNECT_ONE_SHOT)

	if not loading:
		changed.emit()
	return item


func add_node_item(parent:TreeItem, data := {}) -> TreeItem:
	var item := create_item(parent)

	item.set_text(0, data.name)
	item.set_editable(0, true)

	if data.get("display_name", ""):
		item.set_text(1, data.display_name)
	else:
		item.set_text(1, data.name.trim_prefix("%").get_slice("/", data.name.get_slice_count("/")-1))
	item.set_editable(1, true)

	item.set_text(2, data.get("tooltip", ""))

	item.set_custom_bg_color(0, get_theme_color("prop_subsection_stylebox_color", "Editor"))
	item.set_custom_bg_color(1, get_theme_color("prop_subsection_stylebox_color", "Editor"))
	item.set_custom_bg_color(2, get_theme_color("prop_subsection_stylebox_color", "Editor"))

	item.add_button(3, get_theme_icon("ToolSelect", "EditorIcons"), Buttons.SELECT, false, "Select")
	item.add_button(3, get_theme_icon("Remove", "EditorIcons"), Buttons.DELETE, false, "Delete All Node Customization")

	item.set_metadata(0, {"type":"Node", "node_path":data.name})
	item.set_cell_mode(3, TreeItem.CELL_MODE_CUSTOM)

	item.collapsed = data.get("collapsed", false)

	if not loading:
		changed.emit()

	return item


func add_property_item(parent:TreeItem, data := {}) -> TreeItem:
	var item := create_item(parent)

	item.set_text(0, data.name)
	item.set_editable(0, true)
	item.set_custom_color(0, get_theme_color("font_placeholder_color", "Editor"))

	if data.get("display_name", ""):
		item.set_text(1, data.display_name)
	else:
		item.set_text(1, simplify_name(data.name))
	item.set_editable(1, true)

	item.set_text(2, data.get("tooltip", ""))
	item.set_editable(2, true)

	item.add_button(3, get_theme_icon("Remove", "EditorIcons"), Buttons.DELETE, false, "Delete This Property Customization")
	item.set_metadata(0, {"type":"Property"})
	item.set_cell_mode(3, TreeItem.CELL_MODE_CUSTOM)

	item.collapsed = data.get("collapsed", false)

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
	property_path = property_path.replace("theme_override_styles/", "Stylebox ")
	property_path = property_path.replace("theme_override_colors/", "")
	property_path = property_path.replace("theme_override_constants/", "")
	property_path = property_path.replace("theme_override_fonts/", "")
	property_path = property_path.replace("theme_override_font_sizes/", "")
	property_path = property_path.replace("theme_override_icons/", "Icon ")
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


func highlight_property(node:Node, property:String) -> void:
	var item := get_root().get_child(0)
	var current_node: Node = null
	var current_node_path := ""
	var highlight_items := []
	while item:
		var dt: Dictionary = item.get_metadata(0)
		if dt.type == "Node":
			current_node = get_item_scene_node(item)
			current_node_path = item.get_text(0)
		if dt.type == "Property":
			if item.get_text(0) == property:
				if current_node == node or (current_node_path.ends_with("/@all_children") and current_node.get_parent() == node.get_parent()):
					highlight_items.append(item)
					break
		item = item.get_next_in_tree()

	if highlight_items.is_empty():
		return

	for i in highlight_items:
		i.uncollapse_tree()
		i.select(0)
		scroll_to_item(i)


func _on_mouse_exited() -> void:
	%DropInfoLabel.hide()
	%AddCategory.show()
