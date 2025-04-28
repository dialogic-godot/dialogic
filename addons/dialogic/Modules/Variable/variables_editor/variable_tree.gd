@tool
extends Tree

enum TreeButtons {ADD_FOLDER, ADD_VARIABLE, DUPLICATE_FOLDER, DELETE, CHANGE_TYPE}

@onready var editor: DialogicEditor = find_parent("VariablesEditor")

var validation_regex := RegEx.create_from_string(r"[^\w]")

var undo := UndoRedo.new()

#region INITIAL SETUP

func _ready() -> void:
	set_column_title(0, "Name")
	set_column_title(1, "")
	set_column_title(2, "Default Value")
	set_column_expand(1, false)
	set_column_expand_ratio(2, 2)
	set_column_title_alignment(0, 0)
	set_column_title_alignment(2, 0)

	%ChangeTypePopup.self_modulate = get_theme_color("dark_color_3", "Editor")
	%ChangeTypePopup.theme.set_stylebox('pressed', 'Button', get_theme_stylebox("LaunchPadMovieMode", "EditorStyles"))
	%ChangeTypePopup.theme.set_stylebox('hover', 'Button', get_theme_stylebox("LaunchPadMovieMode", "EditorStyles"))
	for child in %ChangeTypePopup/HBox.get_children():
		child.toggled.connect(_on_type_pressed.bind(child.get_index()+1))
		child.icon = get_theme_icon(["String", "float", "int", "bool"][child.get_index()], "EditorIcons")

	%RightClickMenu.set_item_icon(0, get_theme_icon("ActionCopy", "EditorIcons"))
#endregion


#region POPULATING THE TREE

func load_info(dict:Dictionary, parent:TreeItem = null, is_new:=false) -> void:
	if parent == null:
		clear()
		parent = add_folder_item("VAR", null)

	var sorted_keys := dict.keys()
	sorted_keys.sort()
	for key in sorted_keys:
		if typeof(dict[key]) != TYPE_DICTIONARY:
			var item := add_variable_item(key, dict[key], parent)
			if is_new:
				item.set_meta("new", true)

	for key in sorted_keys:
		if typeof(dict[key]) == TYPE_DICTIONARY:
			var folder := add_folder_item(key, parent)
			if is_new:
				folder.set_meta("new", true)
			load_info(dict[key], folder, is_new)


func add_variable_item(item_name:String, value:Variant, parent:TreeItem) -> TreeItem:
	var item := create_item(parent)
	item.set_meta("type", "VARIABLE")

	item.set_text(0, item_name)
	item.set_editable(0, true)
	item.set_metadata(0, item_name)
	item.set_icon(0, load(DialogicUtil.get_module_path('Variable').path_join("variable.svg")))

	var folder_color: Color = parent.get_meta('color', Color.TRANSPARENT)
	folder_color.a *= 0.5
	item.set_custom_bg_color(0, folder_color.lerp(get_theme_color("background", "Editor"), 0.5))

	item.add_button(1, get_theme_icon("String", "EditorIcons"), TreeButtons.CHANGE_TYPE)
	set_variable_value(item, DialogicUtil.get_variable_value_type(value), value)
	item.set_editable(2, true)
	item.add_button(2, get_theme_icon("Remove", "EditorIcons"), TreeButtons.DELETE)

	item.set_meta('prev_path', get_item_path(item))
	return item


func add_folder_item(item_name:String, parent:TreeItem) -> TreeItem:
	var item := create_item(parent)
	item.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
	item.set_meta("type", "FOLDER")
	item.set_text(0, item_name)
	item.set_metadata(0, item_name)
	item.set_editable(0, item != get_root())

	var folder_color := Color.TRANSPARENT
	if parent == null:
		#folder_color = Color.TRANSPARENT#
		folder_color = Color(0.33000001311302, 0.15179999172688, 0.15179999172688)
	else:
		var parent_color: Color = parent.get_meta('color', Color(0.33000001311302, 0.15179999172688, 0.15179999172688))
		folder_color = parent_color

	var level := 1
	var i := item
	while i.get_parent():
		i = i.get_parent()
		level += 1

	var parent_vars_count := 0
	if parent:
		parent_vars_count = parent.get_children().reduce(func(x, y): return x + 1 if y.get_meta("type") == "VARIABLE" else x, 0)

	if level == 2:
		folder_color.h = wrap(folder_color.h+0.15*(item.get_index()-parent_vars_count+1), 0, 1)
		#folder_color = folder_color.lerp(get_theme_color("background", "Editor"), 0.1*level)
	elif level == 3:
		folder_color.h = wrap(folder_color.h-0.1*(item.get_index()-parent_vars_count+1), 0, 1)
	elif level == 4:
		folder_color.h = wrap(folder_color.h+0.1*(item.get_index()-parent_vars_count+1), 0, 1)

	folder_color = folder_color.lerp(get_theme_color("background", "Editor"), 0.25)
	item.set_custom_bg_color(0, folder_color)
	item.set_custom_bg_color(1, folder_color)
	item.set_custom_bg_color(2, folder_color)
	item.set_meta('color', folder_color)

	item.add_button(2, load(self.get_script().get_path().get_base_dir().get_base_dir() + "/add-variable.svg"), TreeButtons.ADD_VARIABLE)
	item.add_button(2, load("res://addons/dialogic/Editor/Images/Pieces/add-folder.svg"), TreeButtons.ADD_FOLDER)
	item.add_button(2, get_theme_icon("Duplicate", "EditorIcons"), TreeButtons.DUPLICATE_FOLDER, item == get_root())
	item.add_button(2, get_theme_icon("Remove", "EditorIcons"), TreeButtons.DELETE, item == get_root())

	return item


#endregion


#region EDITING THE TREE

func set_variable_item_type(item:TreeItem, type:int) -> void:
	item.set_meta('value_type', type)
	item.set_button(1, 0, get_theme_icon(["Variant", "String", "float", "int", "bool"][type], "EditorIcons"))


func get_variable_item_default(item:TreeItem) -> Variant:
	match int(item.get_meta('value_type', DialogicUtil.VarTypes.STRING)):
		DialogicUtil.VarTypes.STRING:
			return item.get_text(2)
		DialogicUtil.VarTypes.FLOAT:
			return item.get_range(2)
		DialogicUtil.VarTypes.INT:
			return int(item.get_range(2))
		DialogicUtil.VarTypes.BOOL:
			return item.is_checked(2)
	return ""


func _on_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	match id:
		TreeButtons.ADD_FOLDER, TreeButtons.ADD_VARIABLE:
			var new_item_name := ""
			if id == TreeButtons.ADD_FOLDER:
				new_item_name = validate_name(item, "NewFolder")
				item_add_undoable(item, new_item_name, "FOLDER", {})
			else:
				new_item_name = validate_name(item, "NewVar")
				item_add_undoable(item, new_item_name, "VARIABLE", "")
			await get_tree().process_frame
			var new_item := get_path_item(get_item_path(item, new_item_name))
			new_item.select(0)
			new_item.set_meta("new", true)
			await get_tree().process_frame
			edit_selected()
		TreeButtons.DELETE:
			item_remove_undoable(item)
		TreeButtons.DUPLICATE_FOLDER:
			var new_folder_name := validate_name(item.get_parent(), item.get_text(0))
			item_add_undoable(item.get_parent(), new_folder_name, "FOLDER", get_info(item))
		TreeButtons.CHANGE_TYPE:
			%ChangeTypePopup.show()
			%ChangeTypePopup.set_meta('item', item)
			%ChangeTypePopup.position = get_local_mouse_position()+Vector2(-%ChangeTypePopup.size.x/2, 10)
			for child in %ChangeTypePopup/HBox.get_children():
				child.set_pressed_no_signal(false)
			%ChangeTypePopup/HBox.get_child(int(item.get_meta('value_type', DialogicUtil.VarTypes.STRING)-1)).set_pressed_no_signal(true)


func _on_type_pressed(_pressed:bool, type:int) -> void:
	%ChangeTypePopup.hide()
	# This is a MESS.
	# Basically there are two ways a variable value can change:
	# - by being set edited the tree
	# - by the type being changed
	# The problem is that to make the first undoable, we always store the value in the metadata as well.
	# When we detect an edit (in _on_item_edited) we commit the do/undo actions which edit the value AGAIN.
	# But here, where we change the type we now have to edit the type two times as well.
	# There might be a better way but who cares...
	var item: TreeItem = %ChangeTypePopup.get_meta('item')
	var old_value: Variant = item.get_metadata(2)
	set_variable_value(item, type, item.get_metadata(2))
	var new_value: Variant = get_variable_item_default(item)
	if typeof(new_value) != typeof(old_value) or new_value != old_value:
		item.set_metadata(2, old_value)
		item_change_value_undoable(item)


func _on_item_edited() -> void:
	var item := get_edited()
	match item.get_meta('type'):
		"VARIABLE":
			match get_edited_column():
				0:
					if item.get_text(0).is_empty():
						item.set_text(0, item.get_metadata(0))
					else:
						validate_name(item)
						if item.get_text(0) != item.get_metadata(0):
							item_rename_undoable(item)
				2:
					if get_variable_item_default(item) != item.get_metadata(2):
						item_change_value_undoable(item)
		"FOLDER":
			if item.get_text(0) != item.get_metadata(0):
				validate_name(item)
				item_rename_undoable(item)


func item_add_undoable(parent_item:TreeItem, item_name:String, type:String, value:Variant) -> void:
	undo.create_action("Add Item")
	undo.add_do_method(
		add_item.bind(
			get_item_path(parent_item),
			item_name,
			type,
			value)
			)
	undo.add_undo_method(remove_item.bind(get_item_path(parent_item, item_name)))
	undo.commit_action()


func add_item(parent_path:String, text:String, type:String, value:Variant) -> void:
	var parent_item := get_path_item(parent_path)
	match type:
		"VARIABLE":
			add_variable_item(text, value, parent_item)
		"FOLDER":
			load_info({text:value}, parent_item, true)


func item_remove_undoable(item:TreeItem) -> void:
	undo.create_action("Remove Item")
	undo.add_do_method(remove_item.bind(get_item_path(item)))
	undo.add_undo_method(
		add_item.bind(
			get_item_path(item.get_parent()),
			item.get_text(0),
			item.get_meta("type"),
			get_variable_item_default(item) if item.get_meta("type") == "VARIABLE" else get_info(item))
			)
	undo.commit_action()

func remove_item(item_path:String) -> void:
	get_path_item(item_path).free()


func item_rename_undoable(item:TreeItem) -> void:
	var new_item_path := get_item_path(item)
	var new_name := item.get_text(0)
	var old_name: String = item.get_metadata(0)
	item.set_text(0, item.get_metadata(0))
	var old_item_path := get_item_path(item)
	undo.create_action("Renamed Item")
	undo.add_do_method(item_rename.bind(old_item_path, new_name, old_name))
	undo.add_undo_method(item_rename.bind(new_item_path, old_name, new_name))
	undo.commit_action()


func item_rename(item_path:String, new_name:String, old_name:String) -> void:
	var item := get_path_item(item_path)
	if item.get_text(0) == old_name:
		item.set_text(0, new_name)
	report_name_changes(item)
	item.set_metadata(0, item.get_text(0))


func item_change_value_undoable(item:TreeItem) -> void:
	var item_path := get_item_path(item)
	var old_value: Variant = item.get_metadata(2)
	var new_value: Variant = get_variable_item_default(item)

	undo.create_action("Change Variable")
	undo.add_do_method(item_change_value.bind(item_path, new_value))
	undo.add_undo_method(item_change_value.bind(item_path, old_value))
	undo.commit_action()


func item_change_value(item_path:String, value:Variant) -> void:
	#print("SET VARIABLE VALUE ", value)
	var item := get_path_item(item_path)
	set_variable_value(item, DialogicUtil.get_variable_value_type(value), value)
	item.set_metadata(2, value)


func validate_name(item:TreeItem, check_for_imaginary_child := "") -> String:
	var item_name := item.get_text(0)
	var item_parent := item.get_parent()
	if check_for_imaginary_child:
		item_name = check_for_imaginary_child
		item_parent = item
	if not item_name.is_valid_identifier():
		item_name = validation_regex.sub(item_name, "_", true)
	if not item_name.is_valid_identifier():
		item_name = "_"+item_name

	var sibling_names := []

	for i in item_parent.get_children():
		if i == item:
			continue
		sibling_names.append(i.get_text(0))

	if item_name in sibling_names:
		var number_regex := RegEx.create_from_string(r"(?<=\w)\d+$")
		var res := number_regex.search(item_name)
		var x := 2
		if res:
			var number := res.get_string()
			x = int(number)
			item_name = item_name.trim_suffix(number)

		while item_name + str(x) in sibling_names:
			x += 1

		item_name = item_name + str(x)

	if not check_for_imaginary_child:
		item.set_text(0, item_name)

	return item_name


func set_variable_value(item:TreeItem, type:int, prev_value:Variant) -> void:
	set_variable_item_type(item, type)
	match type:
		DialogicUtil.VarTypes.STRING:
			item.set_metadata(2, str(prev_value))
			item.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			item.set_text(2, str(prev_value))
		DialogicUtil.VarTypes.FLOAT:
			item.set_metadata(2, float(prev_value))
			item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			item.set_range_config(2, -9999, 9999, 0.001, false)
			item.set_range(2, float(prev_value))
		DialogicUtil.VarTypes.INT:
			item.set_metadata(2, int(prev_value))
			item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			item.set_range_config(2, -9999, 9999, 1, false)
			item.set_range(2, int(prev_value))
		DialogicUtil.VarTypes.BOOL:
			item.set_metadata(2, prev_value and true)
			item.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			item.set_checked(2, prev_value and true)


func _input(event:InputEvent) -> void:
	if get_window().has_focus() and is_visible_in_tree() and event is InputEventKey and event.is_pressed():
		match event.as_text():
			"Ctrl+Z":
				undo.undo()
				accept_event()
			"Ctrl+Y", "Ctrl+Shift+Z":
				undo.redo()
				accept_event()
	if !%ChangeTypePopup.visible:
		return
	if event is InputEventMouseButton and event.pressed:
		if not %ChangeTypePopup.get_global_rect().has_point(get_global_mouse_position()):
			%ChangeTypePopup.hide()


#endregion


func filter(filter_term:String, item:TreeItem = null) -> bool:
	if item == null:
		item = get_root()

	var any := false
	for child in item.get_children():
		match child.get_meta('type'):
			"VARIABLE":
				child.visible = filter_term.is_empty() or filter_term.to_lower() in child.get_text(0).to_lower()

			"FOLDER":
				child.visible = filter(filter_term, child)
		if child.visible:
			any = true
	return any


## Parses the tree and returns a dictionary representing it.
func get_info(item:TreeItem = null) -> Dictionary:
	if item == null:
		item = get_root()
		if item == null:
			return {}

	var dict := {}

	for child in item.get_children():
		match child.get_meta('type'):
			"VARIABLE":
				dict[child.get_text(0)] = child.get_metadata(2)
			"FOLDER":
				dict[child.get_text(0)] = get_info(child)

	return dict


#region DRAG AND DROP
################################################################################

func _get_drag_data(_position:Vector2) -> Variant:
	drop_mode_flags = DROP_MODE_INBETWEEN
	var preview := Label.new()
	preview.text = "     "+get_selected().get_text(0)
	preview.add_theme_stylebox_override('normal', get_theme_stylebox("Background", "EditorStyles"))
	set_drag_preview(preview)

	return get_selected()


func _can_drop_data(_position:Vector2, data:Variant) -> bool:
	return data is TreeItem


func _drop_data(drop_position:Vector2, item:Variant) -> void:
	var to_item := get_item_at_position(drop_position)

	if !to_item:
		return

	var drop_section := get_drop_section_at_position(drop_position)
	var parent: TreeItem = null
	if (drop_section == 1 and to_item.get_meta('type') == "FOLDER") or to_item == get_root():
		parent = to_item
	else:
		parent = to_item.get_parent()

	## Test for inheritance-recursion
	var test_item := to_item
	while true:
		if test_item == item:
			return
		test_item = test_item.get_parent()
		if test_item == get_root():
			break

	var new_item: TreeItem = null
	match item.get_meta('type'):
		"VARIABLE":
			new_item = add_variable_item(item.get_text(0), item.get_metadata(2), parent)
			new_item.set_meta('prev_path', get_item_path(item))
			if item.get_meta("new", false):
				new_item.set_meta("new", true)
		"FOLDER":
			new_item = add_folder_item(item.get_text(0), parent)
			load_info(get_info(item), new_item)
			if item.get_meta("new", false):
				new_item.set_meta("new", true)

	# If this was dropped on a variable (or the root node)
	if to_item != parent:
		if drop_section == -1:
			new_item.move_before(to_item)
		else:
			new_item.move_after(to_item)

	report_name_changes(new_item)

	item.free()

#endregion


#region NAME CHANGES
################################################################################

func report_name_changes(item:TreeItem) -> void:
	match item.get_meta('type'):
		"VARIABLE":
			if item.get_meta("new", false):
				return
			var new_path := get_item_path(item)
			editor.variable_renamed(item.get_meta('prev_path'), new_path)
			item.set_meta('prev_path', new_path)
		"FOLDER":
			for child in item.get_children():
				report_name_changes(child)


func get_item_path(item:TreeItem, imaginary_child:String = "") -> String:
	var path := ""
	if item != get_root():
		path = item.get_text(0)
	while item != get_root() and item.get_parent() != get_root():
		item = item.get_parent()
		path = item.get_text(0)+"."+path
	if imaginary_child:
		if path:
			path += "."+imaginary_child
		else:
			path = imaginary_child
	return path


func get_path_item(path:String) -> TreeItem:
	var paths := Array(path.split(".", false))
	var item := get_root()
	while paths:
		var found := false
		for i in item.get_children():
			if i.get_text(0) == paths[0]:
				item = i
				paths.pop_front()
				found = true
				break
		if not found:
			break

	if get_item_path(item) != path:
		return null
	return item

#endregion


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MASK_RIGHT and event.pressed:
		var item := get_item_at_position(get_local_mouse_position())
		if item and item != get_root():
			%RightClickMenu.popup_on_parent(Rect2(get_global_mouse_position(), Vector2()))
			%RightClickMenu.set_item_text(0, 'Copy "' + get_item_path(item) + '"')
			%RightClickMenu.set_meta("item", item)
			%RightClickMenu.size = Vector2()


func _on_right_click_menu_id_pressed(id: int) -> void:
	if %RightClickMenu.get_meta("item", null) == null:
		return
	match id:
		0:
			DisplayServer.clipboard_set(get_item_path(%RightClickMenu.get_meta("item")))
