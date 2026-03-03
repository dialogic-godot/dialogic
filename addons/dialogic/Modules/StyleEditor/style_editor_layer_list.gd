@tool
extends Control

var _minimum_tree_item_height: int

@onready var tree: Tree = %LayerTree

signal layer_selected(id:String)

var unre : UndoRedo

var ignore_select := false

func _ready() -> void:
	if owner.get_parent() is SubViewport:
		return

	unre = owner.unre
	_minimum_tree_item_height = int(DialogicUtil.get_editor_scale() * 16)
	tree.add_theme_constant_override("icon_max_width", _minimum_tree_item_height)
	tree.item_selected.connect(_on_layer_selected)

	%AddLayerButton.get_popup().index_pressed.connect(_on_add_layer_menu_pressed)
	%ReplaceLayerButton.get_popup().index_pressed.connect(_on_replace_layer_menu_pressed)
	var make_custom_menu: PopupMenu = %MakeCustomButton.get_popup()
	make_custom_menu.index_pressed.connect(_on_make_custom_menu_pressed)
	make_custom_menu.set_item_tooltip(2, "Creates a copy of the selected layers scene.")
	make_custom_menu.set_item_tooltip(3, "Creates a new scene with the layer scenes instanced, allowing you to then selectively use 'Editable Children' or 'Make Local' on those scenes.")

	%AddLayerButton.icon = get_theme_icon("Add", "EditorIcons")
	%DeleteLayerButton.icon = get_theme_icon("Remove", "EditorIcons")
	%ReplaceLayerButton.icon = get_theme_icon("Loop", "EditorIcons")
	%MakeCustomButton.icon = get_theme_icon("CreateNewSceneFrom", "EditorIcons")


func get_current_style() -> DialogicStyle:
	return get_parent().current_style


func get_current_layer_id() -> String:
	return get_parent().current_layer_id


#region LOADING LIST
################################################################################

func load_style_layer_list(style:DialogicStyle = get_current_style()) -> void:
	%AddLayerButton.disabled = style.inherits_anything()
	%ReplaceLayerButton.disabled = style.inherits_anything()
	%MakeCustomButton.disabled = (style.inherits_anything() or (
		style.layer_list.is_empty() and not %StyleBrowser.is_premade_style_part(style.get_layer_info("").path)))
	%DeleteLayerButton.disabled = style.inherits_anything()

	tree.clear()

	var root := tree.create_item()

	var base_layer_info := style.get_layer_inherited_info("")
	setup_layer_tree_item(base_layer_info, root)

	for layer_id in style.get_layer_inherited_list():
		var layer_info := style.get_layer_inherited_info(layer_id)
		var layer_item := tree.create_item(root)
		setup_layer_tree_item(layer_info, layer_item)

	select_layer(get_current_layer_id(), true)


func setup_layer_tree_item(info:Dictionary, item:TreeItem) -> void:
	item.custom_minimum_height = _minimum_tree_item_height
	if %StyleBrowser.is_premade_style_part(info.path):
		var part_info: Dictionary = %StyleBrowser.premade_scenes_reference[info.path]
		if ResourceLoader.exists(part_info.get("icon", "")):
			item.set_icon(0, load(part_info.get("icon")))
			if part_info.get("color", "") in DialogicUtil.get_color_palette():
				item.set_icon_modulate(0, DialogicUtil.get_color(part_info.color))
			elif part_info.get("color", ""):
				item.set_icon_modulate(0, Color.from_string(part_info.color, Color.WHITE))
		elif item.get_parent():
			item.set_icon(0, get_theme_icon("Breakpoint", "EditorIcons"))
		item.set_text(0, part_info.get("name", "Layer"))
		#item.add_button(0, get_theme_icon("PackedScene", "EditorIcons"))

	else:
		item.set_text(0, clean_scene_name(info.path))
		item.set_icon(0, get_theme_icon("PackedScene", "EditorIcons"))
		item.add_button(0, get_theme_icon("PackedScene", "EditorIcons"), -1, false, "Open Scene")
		item.set_button_tooltip_text(0, 0, "Open Scene")
	item.set_meta("scene", info.path)
	item.set_meta("id", info.id)


func select_layer(id:String, no_signal:= false) -> void:
	ignore_select = no_signal
	if id == "":
		tree.get_root().select(0)
		ignore_select = false
		return

	for child in tree.get_root().get_children():
		if child.get_meta("id", "") == id:
			child.select(0)
			ignore_select = false
			return



func _on_layer_selected() -> void:
	if ignore_select: return
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


func replace_layer(layer_id:String, scene_path:String, clear_overrides:=false) -> void:
	unre.create_action("Replace Layer")
	unre.add_do_method(get_current_style().set_layer_scene.bind(layer_id, scene_path))
	if clear_overrides:
		unre.add_do_method(get_current_style().set_layer_overrides.bind(layer_id, {}))
	unre.add_do_method(load_style_layer_list)
	var current_info := get_current_style().get_layer_info(layer_id)
	unre.add_undo_method(get_current_style().set_layer_scene.bind(layer_id, current_info.path))
	if clear_overrides:
		unre.add_undo_method(get_current_style().set_layer_overrides.bind(layer_id, current_info.overrides))
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
	%MakeLayerCustomText.hide()
	%MakeLayoutCustomText.hide()
	%KeepSettingsExposedSection.hide()
	# This layer only
	if index == 2:
		%CustomizePopup.title = "Customize Layer Scene"
		%CustomizePopup.popup_centered_clamped(Vector2(300, 200))
		%MakeLayerCustomText.show()
		%KeepSettingsExposedSection.show()
		%CustomizePopup.set_meta("mode", "LAYER")
		%ApplySettingsHintTooltip.hint_text = "If you have made any adjustments to the overrides of this scene, this will apply them to the nodes in the new scene, essentially making those values the new default."
	# The full layout
	if index == 3:
		%CustomizePopup.title = "Customize Full Layout"
		%CustomizePopup.popup_centered_clamped(Vector2(300, 100))
		%MakeLayoutCustomText.show()
		%CustomizePopup.set_meta("mode", "FULL_LAYOUT")
		%ApplySettingsHintTooltip.hint_text = "If you have made adjustments to the overrides of any layer, that layer will have 'editable children' enabled. The settings will be applied but not be exposed to the style editor anymore. \n\n[color=red]If this is disabled, all adjustments/overrides will be lost and all layers will be instanced.[/color]\n\nYou could then make them local or use 'editable children' on them yourself."


func _on_customize_layer_popup_confirmed() -> void:
	if %CustomizePopup.get_meta("mode", "") == "LAYER":
		var current_layer_file: String = get_current_style().get_layer_info(get_current_layer_id()).path
		if current_layer_file.begins_with("uid:"):
			current_layer_file = ResourceUID.uid_to_path(current_layer_file)

		find_parent("EditorView").godot_file_dialog(
			_on_make_custom_layer_file_selected.bind(%ApplySettings.button_pressed, %KeepSettingsExposed.button_pressed),
			"*.tscn",
			EditorFileDialog.FILE_MODE_SAVE_FILE,
			"Create new copy of layer scene",
			"custom_"+current_layer_file.get_file())

	else:
		var current_style_name: String = get_current_style().name.to_snake_case()
		find_parent("EditorView").godot_file_dialog(
			_on_make_custom_layout_file_selected.bind(%ApplySettings.button_pressed),
			"*.tscn",
			EditorFileDialog.FILE_MODE_SAVE_FILE,
			"Create a new scene from all layers",
			current_style_name+"_full_layout_customized"
			)


func _on_make_custom_layer_file_selected(file:String, apply_settings:=true, keep_settings_exposed:=true) -> void:
	make_layer_custom(file.get_base_dir(), file.get_file(), apply_settings, keep_settings_exposed)


func _on_make_custom_layout_file_selected(file:String, apply_settings:=true) -> void:
	make_layout_custom(file, apply_settings)


func make_layer_custom(target_folder:String, custom_name := "", apply_settings:=true, keep_settings_exposed:=true) -> void:
	var original_file: String = get_current_style().get_layer_info(get_current_layer_id()).path
	#var custom_new_folder := ""

	if custom_name.is_empty():
		custom_name = "custom_"+%StyleBrowser.premade_scenes_reference[original_file].name.to_snake_case()
		#custom_new_folder = %StyleBrowser.premade_scenes_reference[original_file].name.to_pascal_case()

	var result_path := DialogicUtil.make_file_custom(
		original_file,
		target_folder,
		custom_name,
		#custom_new_folder,
		)

	var scene: Node = load(result_path).instantiate()
	var layer_info := get_current_style().get_layer_inherited_info(get_current_layer_id())
	printt(apply_settings, keep_settings_exposed)
	if apply_settings:
		DialogicUtil.apply_scene_export_overrides(scene, layer_info.overrides)

	if not keep_settings_exposed:
		scene.remove_meta("style_customization")

	var pckd_scn := PackedScene.new()
	pckd_scn.pack(scene)
	ResourceSaver.save(pckd_scn, result_path)

	replace_layer(get_current_layer_id(), result_path, true)


func make_layout_custom(target_path:String, apply_settings:bool) -> void:
	var current_style := get_current_style()

	var base_layer_info := current_style.get_layer_info("")
	var base_scene_uid: String = base_layer_info.path

	# Load base scene
	var base_scene_pck: PackedScene = load(base_layer_info.path).duplicate()
	var base_scene := base_scene_pck.instantiate()
	base_scene.name = "Custom" + clean_scene_name(base_scene_pck.resource_path).to_pascal_case()
	DialogicUtil.apply_scene_export_overrides(base_scene, base_layer_info.overrides)
	base_scene.remove_meta("style_customization")


	# Load layers
	for layer_id in current_style.get_layer_inherited_list():
		var layer_info := current_style.get_layer_inherited_info(layer_id)

		if not ResourceLoader.exists(layer_info.path):
			continue

		var layer_scene: DialogicLayoutLayer = load(layer_info.path).instantiate(PackedScene.GenEditState.GEN_EDIT_STATE_INSTANCE)

		#layer_scene.apply_overrides_on_ready = true
		base_scene.add_layer(layer_scene)

		# Apply layer overrides
		if (not layer_info.overrides.is_empty()) and apply_settings:
			base_scene.set_editable_instance(layer_scene, true)
			DialogicUtil.apply_scene_export_overrides(layer_scene, layer_info.overrides)
		layer_scene.remove_meta("style_customization")
		layer_scene.owner = base_scene

	var pckd_scn := PackedScene.new()
	pckd_scn.pack(base_scene)
	pckd_scn.take_over_path(target_path)
	ResourceSaver.save(pckd_scn, target_path)
	EditorInterface.get_resource_filesystem().scan_sources()

	unre.create_action("Customize Full Layout")
	unre.add_do_method(current_style.clear)
	unre.add_do_method(current_style.set_layer_scene.bind("", target_path))
	unre.add_do_method(load_style_layer_list)
	unre.add_undo_method(current_style.setup.bind(current_style.layer_list, current_style.layer_info, current_style.inherits))
	unre.add_undo_method(load_style_layer_list)
	unre.add_undo_method(func(): print_rich("[color={0}][Dialogic Style] Undoing the full customization of your style will restore your style to it's previous state, but will not delete the new scene that was created.".format([get_theme_color("warning_color", "Editor").to_html()])))
	unre.commit_action()
	#current_style.clear()
	#current_style.set_layer_scene("", target_path)
	#current_style.changed.emit()

	#ResourceSaver.save(current_style)

	#tree.get_root().select(0)



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
	if file_path.begins_with("uid:"):
		file_path = ResourceUID.uid_to_path(file_path)
	return file_path.get_file().trim_suffix(".tscn").capitalize()

#endregion
