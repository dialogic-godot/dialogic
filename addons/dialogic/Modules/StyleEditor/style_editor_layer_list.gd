@tool
extends Control

var _minimum_tree_item_height: int

@onready var tree: Tree = %LayerTree

signal layer_selected(id:String)

var unre : UndoRedo

func _ready() -> void:
	if owner.get_parent() is SubViewport:
		return

	unre = owner.unre
	_minimum_tree_item_height = int(DialogicUtil.get_editor_scale() * 16)
	tree.add_theme_constant_override("icon_max_width", _minimum_tree_item_height)
	tree.item_selected.connect(_on_layer_selected)

	%AddLayerButton.get_popup().index_pressed.connect(_on_add_layer_menu_pressed)
	%ReplaceLayerButton.get_popup().index_pressed.connect(_on_replace_layer_menu_pressed)
	%MakeCustomButton.get_popup().index_pressed.connect(_on_make_custom_menu_pressed)
	%AddLayerButton.icon = get_theme_icon("Add", "EditorIcons")
	%DeleteLayerButton.icon = get_theme_icon("Remove", "EditorIcons")
	%ReplaceLayerButton.icon = get_theme_icon("Loop", "EditorIcons")
	%MakeCustomButton.icon = get_theme_icon("FileAccess", "EditorIcons")


func get_current_style() -> DialogicStyle:
	return get_parent().current_style


func get_current_layer_id() -> String:
	return get_parent().current_layer_id


#region LOADING LIST
################################################################################

func load_style_layer_list(style:DialogicStyle = get_current_style()) -> void:
	%AddLayerButton.disabled = style.inherits_anything()
	%ReplaceLayerButton.disabled = style.inherits_anything()
	%MakeCustomButton.disabled = style.inherits_anything()
	%DeleteLayerButton.disabled = style.inherits_anything()

	tree.clear()

	var root := tree.create_item()

	var base_layer_info := style.get_layer_inherited_info("")
	setup_layer_tree_item(base_layer_info, root)

	for layer_id in style.get_layer_inherited_list():
		var layer_info := style.get_layer_inherited_info(layer_id)
		var layer_item := tree.create_item(root)
		setup_layer_tree_item(layer_info, layer_item)

	select_layer(get_current_layer_id())


func setup_layer_tree_item(info:Dictionary, item:TreeItem) -> void:
	item.custom_minimum_height = _minimum_tree_item_height

	if %StyleBrowser.is_premade_style_part(info.path):
		if ResourceLoader.exists(%StyleBrowser.premade_scenes_reference[info.path].get("icon", "")):
			item.set_icon(0, load(%StyleBrowser.premade_scenes_reference[info.path].get("icon")))
		item.set_text(0, %StyleBrowser.premade_scenes_reference[info.path].get("name", "Layer"))
		#item.add_button(0, get_theme_icon("PackedScene", "EditorIcons"))

	else:
		item.set_text(0, clean_scene_name(info.path))
		item.add_button(0, get_theme_icon("PackedScene", "EditorIcons"))
		item.set_button_tooltip_text(0, 0, "Open Scene")
	item.set_meta("scene", info.path)
	item.set_meta("id", info.id)


func select_layer(id:String) -> void:
	if id == "":
		tree.get_root().select(0)
	else:
		for child in tree.get_root().get_children():
			if child.get_meta("id", "") == id:
				child.select(0)
				return


func _on_layer_selected() -> void:
	var item: TreeItem = tree.get_selected()
	layer_selected.emit(item.get_meta("id", ""))

#endregion


#region LAYER LIST MANIPULATION
################################################################################

func add_layer(scene_path:="", overrides:= {}):
	var new_id := get_current_style().get_new_layer_id()
	unre.create_action("Add Layer")
	unre.add_do_method(get_current_style().add_layer.bind(scene_path, overrides, new_id))
	unre.add_do_method(load_style_layer_list)
	unre.add_do_method(select_layer.bind(new_id))
	unre.add_undo_method(get_current_style().delete_layer.bind(new_id))
	unre.add_undo_method(load_style_layer_list)
	unre.add_undo_method(select_layer.bind(get_current_layer_id()))
	unre.commit_action()


func delete_layer() -> void:
	if get_current_layer_id() == "":
		return
	var layer_info := get_current_style().get_layer_info(get_current_layer_id())
	unre.create_action("Delete Layer")
	unre.add_do_method(get_current_style().delete_layer.bind(get_current_layer_id()))
	unre.add_do_method(load_style_layer_list)
	unre.add_do_method(select_layer.bind(""))
	unre.add_undo_method(get_current_style().add_layer.bind(layer_info.path, layer_info.overrides, layer_info.id))
	unre.add_undo_method(get_current_style().set_layer_index.bind(layer_info.id, get_current_style().get_layer_index(layer_info.id)))
	unre.add_undo_method(load_style_layer_list)
	unre.add_undo_method(select_layer.bind(get_current_layer_id()))
	unre.commit_action()


func move_layer(from_idx:int, to_idx:int) -> void:
	unre.create_action("Move Layer")
	unre.add_do_method(get_current_style().move_layer.bind(from_idx, to_idx))
	unre.add_do_method(load_style_layer_list)
	unre.add_undo_method(get_current_style().move_layer.bind(to_idx, from_idx))
	unre.add_undo_method(load_style_layer_list)
	unre.commit_action()


func replace_layer(layer_id:String, scene_path:String) -> void:
	unre.create_action("Replace Layer")
	unre.add_do_method(get_current_style().set_layer_scene.bind(layer_id, scene_path))
	unre.add_do_method(load_style_layer_list)
	unre.add_undo_method(get_current_style().set_layer_scene.bind(layer_id, get_current_style().get_layer_info(layer_id).path))
	unre.add_undo_method(load_style_layer_list)
	unre.commit_action()

#endregion


#region ADD LAYER MENU
################################################################################

func _on_add_layer_menu_pressed(index:int) -> void:
	# Adding a premade layer
	if index == 2:
		%StyleBrowserWindow.popup_centered_ratio(0.6)
		%StyleBrowser.current_type = 2
		%StyleBrowser.load_parts()
		var picked_info: Dictionary = await %StyleBrowserWindow.get_picked_info()
		if not picked_info.is_empty():
			add_layer(picked_info.get("path", ""))

	# Adding a custom scene as a layer
	else:
		find_parent("EditorView").godot_file_dialog(
			_on_add_custom_layer_file_selected,
			"*.tscn, Scenes",
			EditorFileDialog.FILE_MODE_OPEN_FILE,
			"Open custom layer scene")


func _on_add_custom_layer_file_selected(file_path:String) -> void:
	add_layer(file_path)

#endregion


#region REPLACE LAYER MENU
################################################################################

func _on_replace_layer_menu_pressed(index:int) -> void:
	# Adding a premade layer
	if index == 2:
		%StyleBrowserWindow.popup_centered_ratio(0.6)
		if tree.get_selected() == tree.get_root():
			%StyleBrowser.current_type = 3
		else:
			%StyleBrowser.current_type = 2
		%StyleBrowser.load_parts()
		var picked_info: Dictionary = await %StyleBrowserWindow.get_picked_info()
		if not picked_info.is_empty():
			replace_layer(tree.get_selected().get_meta("id", ""), picked_info.get("path", ""))

	# Adding a custom scene as a layer
	else:
		find_parent("EditorView").godot_file_dialog(
			_on_replace_custom_layer_file_selected,
			"*.tscn, Scenes",
			EditorFileDialog.FILE_MODE_OPEN_FILE,
			"Open custom layer scene")


func _on_replace_custom_layer_file_selected(file_path:String) -> void:
	replace_layer(tree.get_selected().get_meta("id", ""), file_path)

#endregion


#region MAKE CUSTOM LAYER MENU
################################################################################

func _on_make_custom_button_about_to_popup() -> void:
	%MakeCustomButton.get_popup().set_item_disabled(2, false)
	%MakeCustomButton.get_popup().set_item_disabled(3, false)

	if not %StyleBrowser.is_premade_style_part(get_current_style().get_layer_info(get_current_layer_id()).path):
		%MakeCustomButton.get_popup().set_item_disabled(2, true)


func _on_make_custom_menu_pressed(index:int) -> void:
	# This layer only
	if index == 2:
		find_parent("EditorView").godot_file_dialog(
			_on_make_custom_layer_file_selected,
			"",
			EditorFileDialog.FILE_MODE_OPEN_DIR,
			"Select folder for new copy of layer")
	# The full layout
	if index == 3:
		find_parent("EditorView").godot_file_dialog(
			_on_make_custom_layout_file_selected,
			"",
			EditorFileDialog.FILE_MODE_OPEN_DIR,
			"Select folder for new layout scene")


func _on_make_custom_layer_file_selected(file:String) -> void:
	make_layer_custom(file)


func _on_make_custom_layout_file_selected(file:String) -> void:
	make_layout_custom(file)


func make_layer_custom(target_folder:String, custom_name := "") -> void:
	var original_file: String = get_current_style().get_layer_info(get_current_layer_id()).path
	var custom_new_folder := ""

	if custom_name.is_empty():
		custom_name = "custom_"+%StyleBrowser.premade_scenes_reference[original_file].name.to_snake_case()
		custom_new_folder = %StyleBrowser.premade_scenes_reference[original_file].name.to_pascal_case()

	var result_path := DialogicUtil.make_file_custom(
		original_file,
		target_folder,
		custom_name,
		custom_new_folder,
		)

	get_current_style().set_layer_scene(get_current_layer_id(), result_path)

	load_style_layer_list()

	if tree.get_selected() == tree.get_root():
		tree.get_root().select(0)
	else:
		tree.get_root().get_child(tree.get_selected().get_index()).select(0)


func make_layout_custom(target_folder:String) -> void:
	var current_style := get_current_style()
	target_folder = target_folder.path_join("Custom" + current_style.name.to_pascal_case())

	DirAccess.make_dir_absolute(target_folder)
	tree.get_root().select(0)
	make_layer_custom(target_folder, "custom_" + current_style.name.to_snake_case())

	var base_layer_info := current_style.get_layer_info("")
	var target_path: String = base_layer_info.path

	# Load base scene
	var base_scene_pck: PackedScene = load(base_layer_info.path).duplicate()
	var base_scene := base_scene_pck.instantiate()
	base_scene.name = "Custom" + clean_scene_name(base_scene_pck.resource_path).to_pascal_case()

	var pckd_scn := PackedScene.new()
	pckd_scn.take_over_path(target_path)

	# Load layers
	for layer_id in current_style.get_layer_inherited_list():
		var layer_info := current_style.get_layer_inherited_info(layer_id)

		if not ResourceLoader.exists(layer_info.path):
			continue

		var layer_scene: DialogicLayoutLayer = load(layer_info.path).instantiate()

		base_scene.add_layer(layer_scene)
		layer_scene.owner = base_scene
		layer_scene.apply_overrides_on_ready = true

		# Apply layer overrides
		DialogicUtil.apply_scene_export_overrides(layer_scene, layer_info.overrides, false)

	pckd_scn.pack(base_scene)
	ResourceSaver.save(pckd_scn, target_path)

	current_style.clear()
	current_style.set_layer_scene("", target_path)
	current_style.changed.emit()

	ResourceSaver.save(current_style)

	load_style_layer_list()

	tree.get_root().select(0)
	EditorInterface.get_resource_filesystem().scan_sources()


func _on_delete_layer_button_pressed() -> void:
	delete_layer()

#endregion


#region LAYER LIST INTERACTION
################################################################################

func _on_layer_tree_layer_moved(from: int, to: int) -> void:
	move_layer(from, to)


func _on_layer_tree_button_clicked(item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	get_parent().edit_layer_scene(item.get_meta("scene"))


#endregion


#region HELPERS
################################################################################

func clean_scene_name(file_path:String) -> String:
	return file_path.get_file().trim_suffix(".tscn").capitalize()

#endregion
