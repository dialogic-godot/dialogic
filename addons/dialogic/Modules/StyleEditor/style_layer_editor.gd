@tool
extends HSplitContainer

## Script that handles the style editor.


var current_style: DialogicStyle = null

var customization_editor_info := {}

## The id of the currently selected layer.
## "" is the base scene.
var current_layer_id := ""

var _minimum_tree_item_height: int

@onready var tree: Tree = %LayerTree


func _ready() -> void:
	# Styling
	%AddLayerButton.icon = get_theme_icon("Add", "EditorIcons")
	%DeleteLayerButton.icon = get_theme_icon("Remove", "EditorIcons")
	%ReplaceLayerButton.icon = get_theme_icon("Loop", "EditorIcons")
	%MakeCustomButton.icon = get_theme_icon("FileAccess", "EditorIcons")
	%ExpandLayerInfo.icon = get_theme_icon("CodeFoldDownArrow", "EditorIcons")

	%AddLayerButton.get_popup().index_pressed.connect(_on_add_layer_menu_pressed)
	%ReplaceLayerButton.get_popup().index_pressed.connect(_on_replace_layer_menu_pressed)
	%MakeCustomButton.get_popup().index_pressed.connect(_on_make_custom_menu_pressed)
	%LayerTree.item_selected.connect(_on_layer_selected)
	_minimum_tree_item_height = int(DialogicUtil.get_editor_scale() * 32)
	%LayerTree.add_theme_constant_override("icon_max_width", _minimum_tree_item_height)


func load_style(style:DialogicStyle) -> void:
	current_style = style

	if current_style.has_meta("_latest_layer"):
		current_layer_id = str(current_style.get_meta("_latest_layer", ""))
	else:
		current_layer_id = ""

	%AddLayerButton.disabled = style.inherits_anything()
	%ReplaceLayerButton.disabled = style.inherits_anything()
	%MakeCustomButton.disabled = style.inherits_anything()
	%DeleteLayerButton.disabled = style.inherits_anything()

	load_style_layer_list()


func load_style_layer_list() -> void:
	tree.clear()

	var root := tree.create_item()

	var base_layer_info := current_style.get_layer_inherited_info("")
	setup_layer_tree_item(base_layer_info, root)

	for layer_id in current_style.get_layer_inherited_list():
		var layer_info := current_style.get_layer_inherited_info(layer_id)
		var layer_item := tree.create_item(root)
		setup_layer_tree_item(layer_info, layer_item)

	select_layer(current_layer_id)


func select_layer(id:String) -> void:
	if id == "":
		tree.get_root().select(0)
	else:
		for child in tree.get_root().get_children():
			if child.get_meta("id", "") == id:
				child.select(0)
				return


func setup_layer_tree_item(info:Dictionary, item:TreeItem) -> void:
	item.custom_minimum_height = _minimum_tree_item_height

	if %StyleBrowser.is_premade_style_part(info.path):
		if ResourceLoader.exists(%StyleBrowser.premade_scenes_reference[info.path].get('icon', '')):
			item.set_icon(0, load(%StyleBrowser.premade_scenes_reference[info.path].get("icon")))
		item.set_text(0, %StyleBrowser.premade_scenes_reference[info.path].get("name", "Layer"))

	else:
		item.set_text(0, clean_scene_name(info.path))
		item.add_button(0, get_theme_icon("PackedScene", "EditorIcons"))
		item.set_button_tooltip_text(0, 0, "Open Scene")
	item.set_meta("scene", info.path)
	item.set_meta("id", info.id)


func _on_layer_selected() -> void:
	var item: TreeItem = %LayerTree.get_selected()
	load_layer(item.get_meta("id", ""))


func load_layer(layer_id:=""):
	current_layer_id = layer_id
	current_style.set_meta('_latest_layer', current_layer_id)

	var layer_info := current_style.get_layer_inherited_info(layer_id)

	%SmallLayerPreview.hide()
	if %StyleBrowser.is_premade_style_part(layer_info.get('path', 'Unkown Layer')):
		var premade_infos = %StyleBrowser.premade_scenes_reference[layer_info.get('path')]
		%LayerName.text = premade_infos.get('name', 'Unknown Layer')
		%SmallLayerAuthor.text = "by "+premade_infos.get('author', '')
		%SmallLayerDescription.text = premade_infos.get('description', '')

		if premade_infos.get('preview_image', null) and ResourceLoader.exists(premade_infos.get('preview_image')[0]):
			%SmallLayerPreview.texture = load(premade_infos.get('preview_image')[0])
			%SmallLayerPreview.show()

	else:
		%LayerName.text = clean_scene_name(layer_info.get('path', 'Unkown Layer'))
		%SmallLayerAuthor.text = "Custom Layer"
		%SmallLayerDescription.text = layer_info.get('path', 'Unkown Layer')

	%DeleteLayerButton.disabled = layer_id == "" or current_style.inherits_anything()

	%SmallLayerScene.text = layer_info.get('path', 'Unkown Layer').get_file()
	%SmallLayerScene.tooltip_text = layer_info.get('path', '')

	var inherited_layer_info := current_style.get_layer_inherited_info(layer_id, true)
	load_layout_scene_customization(
			layer_info.path,
			layer_info.overrides,
			inherited_layer_info.overrides)



func add_layer(scene_path:="", overrides:= {}):
	current_style.add_layer(scene_path, overrides)
	load_style_layer_list()
	await get_tree().process_frame
	%LayerTree.get_root().get_child(-1).select(0)


func delete_layer() -> void:
	if current_layer_id == "":
		return

	current_style.delete_layer(current_layer_id)
	load_style_layer_list()
	%LayerTree.get_root().select(0)


func move_layer(from_idx:int, to_idx:int) -> void:
	current_style.move_layer(from_idx, to_idx)

	load_style_layer_list()
	select_layer(current_style.get_layer_id_at_index(to_idx))


func replace_layer(layer_id:String, scene_path:String) -> void:
	current_style.set_layer_scene(layer_id, scene_path)

	load_style_layer_list()
	select_layer(layer_id)


func _on_add_layer_menu_pressed(index:int) -> void:
	# Adding a premade layer
	if index == 2:
		%StyleBrowserWindow.popup_centered_ratio(0.6)
		%StyleBrowser.current_type = 2
		%StyleBrowser.load_parts()
		var picked_info: Dictionary = await %StyleBrowserWindow.get_picked_info()
		if not picked_info.is_empty():
			add_layer(picked_info.get('path', ''))

	# Adding a custom scene as a layer
	else:
		find_parent('EditorView').godot_file_dialog(
			_on_add_custom_layer_file_selected,
			'*.tscn, Scenes',
			EditorFileDialog.FILE_MODE_OPEN_FILE,
			"Open custom layer scene")


func _on_replace_layer_menu_pressed(index:int) -> void:
	# Adding a premade layer
	if index == 2:
		%StyleBrowserWindow.popup_centered_ratio(0.6)
		if %LayerTree.get_selected() == %LayerTree.get_root():
			%StyleBrowser.current_type = 3
		else:
			%StyleBrowser.current_type = 2
		%StyleBrowser.load_parts()
		var picked_info: Dictionary = await %StyleBrowserWindow.get_picked_info()
		if not picked_info.is_empty():
			replace_layer(%LayerTree.get_selected().get_meta("id", ""), picked_info.get('path', ''))

	# Adding a custom scene as a layer
	else:
		find_parent('EditorView').godot_file_dialog(
			_on_replace_custom_layer_file_selected,
			'*.tscn, Scenes',
			EditorFileDialog.FILE_MODE_OPEN_FILE,
			"Open custom layer scene")


func _on_add_custom_layer_file_selected(file_path:String) -> void:
	add_layer(file_path)


func _on_replace_custom_layer_file_selected(file_path:String) -> void:
	replace_layer(%LayerTree.get_selected().get_meta("id", ""), file_path)


func _on_make_custom_button_about_to_popup() -> void:
	%MakeCustomButton.get_popup().set_item_disabled(2, false)
	%MakeCustomButton.get_popup().set_item_disabled(3, false)

	if not %StyleBrowser.is_premade_style_part(current_style.get_layer_info(current_layer_id).path):
		%MakeCustomButton.get_popup().set_item_disabled(2, true)


func _on_make_custom_menu_pressed(index:int) -> void:
	# This layer only
	if index == 2:
		find_parent('EditorView').godot_file_dialog(
			_on_make_custom_layer_file_selected,
			'',
			EditorFileDialog.FILE_MODE_OPEN_DIR,
			"Select folder for new copy of layer")
	# The full layout
	if index == 3:
		find_parent('EditorView').godot_file_dialog(
			_on_make_custom_layout_file_selected,
			'',
			EditorFileDialog.FILE_MODE_OPEN_DIR,
			"Select folder for new layout scene")


func _on_make_custom_layer_file_selected(file:String) -> void:
	make_layer_custom(file)


func _on_make_custom_layout_file_selected(file:String) -> void:
	make_layout_custom(file)


func make_layer_custom(target_folder:String, custom_name := "") -> void:

	var original_file: String = current_style.get_layer_info(current_layer_id).path
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

	current_style.set_layer_scene(current_layer_id, result_path)

	load_style_layer_list()

	if %LayerTree.get_selected() == %LayerTree.get_root():
		%LayerTree.get_root().select(0)
	else:
		%LayerTree.get_root().get_child(%LayerTree.get_selected().get_index()).select(0)


func make_layout_custom(target_folder:String) -> void:
	target_folder = target_folder.path_join("Custom" + current_style.name.to_pascal_case())

	DirAccess.make_dir_absolute(target_folder)
	%LayerTree.get_root().select(0)
	make_layer_custom(target_folder, "custom_" + current_style.name.to_snake_case())


	var base_layer_info := current_style.get_layer_info("")
	var target_path: String = base_layer_info.path

	# Load base scene
	var base_scene_pck: PackedScene = load(base_layer_info.path).duplicate()
	var base_scene := base_scene_pck.instantiate()
	base_scene.name = "Custom" + clean_scene_name(base_scene_pck.resource_path).to_pascal_case()

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

	var pckd_scn := PackedScene.new()
	pckd_scn.pack(base_scene)
	pckd_scn.take_over_path(target_path)
	ResourceSaver.save(pckd_scn, target_path)

	current_style.base_scene = load(target_path)
	current_style.inherits = null
	current_style.layers = []
	current_style.changed.emit()

	load_style_layer_list()

	%LayerTree.get_root().select(0)
	find_parent('EditorView').plugin_reference.get_editor_interface().get_resource_filesystem().scan_sources()



func _on_delete_layer_button_pressed() -> void:
	delete_layer()


#region Layer Settings
####### LAYER SETTINGS #########################################################

func load_layout_scene_customization(custom_scene_path:String, overrides:Dictionary = {}, inherited_overrides:Dictionary = {}) -> void:
	for child in %LayerSettingsTabs.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()

	var scene: Node = null
	if !custom_scene_path.is_empty() and ResourceLoader.exists(custom_scene_path):
		var pck_scn := load(custom_scene_path)
		if pck_scn:
			scene = pck_scn.instantiate()

	var settings := []
	if scene and scene.script:
		settings = collect_settings(scene.script.get_script_property_list())

	if settings.is_empty():
		var note := Label.new()
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.text = "This layer has no exposed settings."
		if not %StyleBrowser.is_premade_style_part(custom_scene_path):
			note.text += "\n\nIf you want to add settings, make sure to have a root script in @tool mode and expose some @exported variables to show up here."
		note.theme_type_variation = 'DialogicHintText2'
		%LayerSettingsTabs.add_child(note)
		note.name = "General"
		return

	var current_grid: GridContainer = null

	var label_bg_style := get_theme_stylebox("CanvasItemInfoOverlay", "EditorStyles").duplicate()
	label_bg_style.content_margin_left = 5
	label_bg_style.content_margin_right = 5
	label_bg_style.content_margin_top = 5

	var current_group_name := ""
	var current_subgroup_name := ""
	customization_editor_info = {}

	for i in settings:
		match i['id']:
			&"GROUP":
				var main_scroll := ScrollContainer.new()
				main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
				main_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				main_scroll.name = i['name']
				%LayerSettingsTabs.add_child(main_scroll, true)

				current_grid = GridContainer.new()
				current_grid.columns = 3
				current_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				main_scroll.add_child(current_grid)
				current_group_name = i['name'].to_snake_case()
				current_subgroup_name = ""

			&"SUBGROUP":

				# add separator
				if current_subgroup_name:
					current_grid.add_child(HSeparator.new())
					current_grid.get_child(-1).add_theme_constant_override('separation', 20)
					current_grid.add_child(current_grid.get_child(-1).duplicate())
					current_grid.add_child(current_grid.get_child(-1).duplicate())

				var title_label := Label.new()
				title_label.text = i['name']
				title_label.theme_type_variation = "DialogicSection"
				title_label.size_flags_horizontal = SIZE_EXPAND_FILL
				current_grid.add_child(title_label, true)

				# add spaced to the grid
				current_grid.add_child(Control.new())
				current_grid.add_child(Control.new())

				current_subgroup_name = i['name'].to_snake_case()

			&"SETTING":
				var label := Label.new()
				label.text = str(i['name'].trim_prefix(current_group_name+'_').trim_prefix(current_subgroup_name+'_')).capitalize()
				current_grid.add_child(label, true)

				var scene_value: Variant = scene.get(i['name'])
				customization_editor_info[i['name']] = {}

				if i['name'] in inherited_overrides:
					customization_editor_info[i['name']]['orig'] = str_to_var(inherited_overrides.get(i['name']))
				else:
					customization_editor_info[i['name']]['orig'] = scene_value

				var current_value: Variant
				if i['name'] in overrides:
					current_value = str_to_var(overrides.get(i['name']))
				else:
					current_value = customization_editor_info[i['name']]['orig']

				var input: Node = DialogicUtil.setup_script_property_edit_node(i, current_value, set_export_override)

				input.size_flags_horizontal = SIZE_EXPAND_FILL
				customization_editor_info[i['name']]['node'] = input

				var reset := Button.new()
				reset.flat = true
				reset.icon = get_theme_icon("Reload", "EditorIcons")
				reset.tooltip_text = "Remove customization"
				customization_editor_info[i['name']]['reset'] = reset
				reset.disabled = current_value == customization_editor_info[i['name']]['orig']
				current_grid.add_child(reset)
				reset.pressed.connect(_on_export_override_reset.bind(i['name']))
				current_grid.add_child(input)

	if scene:
		scene.queue_free()


func collect_settings(properties:Array[Dictionary]) -> Array[Dictionary]:
	var settings: Array[Dictionary] = []

	var current_group := {}
	var current_subgroup := {}

	for i in properties:
		if i['usage'] & PROPERTY_USAGE_CATEGORY == PROPERTY_USAGE_CATEGORY:
			continue

		if i['usage'] & PROPERTY_USAGE_GROUP == PROPERTY_USAGE_GROUP:
			current_group = i
			current_group['added'] = false
			current_group['id'] = &'GROUP'
			current_subgroup = {}

		elif i['usage'] & PROPERTY_USAGE_SUBGROUP == PROPERTY_USAGE_SUBGROUP:
			current_subgroup = i
			current_subgroup['added'] = false
			current_subgroup['id'] = &'SUBGROUP'

		elif i['usage'] & PROPERTY_USAGE_EDITOR == PROPERTY_USAGE_EDITOR:
			if current_group.get('name', '') == 'Private':
				continue

			if current_group.is_empty():
				current_group = {'name':'General', 'added':false, 'id':&"GROUP"}

			if current_group.get('added', true) == false:
				settings.append(current_group)
				current_group['added'] = true

			if current_subgroup.is_empty():
				current_subgroup = {'name':current_group['name'], 'added':false, 'id':&"SUBGROUP"}

			if current_subgroup.get('added', true) == false:
				settings.append(current_subgroup)
				current_subgroup['added'] = true

			i['id'] = &'SETTING'
			settings.append(i)
	return settings


func set_export_override(property_name:String, value:String = "") -> void:
	if str_to_var(value) != customization_editor_info[property_name]['orig']:
		current_style.set_layer_setting(current_layer_id, property_name, value)
		customization_editor_info[property_name]['reset'].disabled = false
	else:
		current_style.remove_layer_setting(current_layer_id, property_name)
		customization_editor_info[property_name]['reset'].disabled = true


func _on_export_override_reset(property_name:String) -> void:
	current_style.remove_layer_setting(current_layer_id, property_name)
	customization_editor_info[property_name]['reset'].disabled = true
	set_customization_value(property_name, customization_editor_info[property_name]['orig'])


func set_customization_value(property_name:String, value:Variant) -> void:
	var node: Node = customization_editor_info[property_name]['node']
	if node is CheckBox:
		node.button_pressed = value
	elif node is LineEdit:
		node.text = value
	elif node.has_method('set_value'):
		node.set_value(value)
	elif node is ColorPickerButton:
		node.color = value
	elif node is OptionButton:
		node.select(value)
	elif node is SpinBox:
		node.value = value

#endregion


func _on_expand_layer_info_pressed() -> void:
	if %LayerInfoBody.visible:
		%LayerInfoBody.hide()
		%ExpandLayerInfo.icon = get_theme_icon("CodeFoldedRightArrow", "EditorIcons")
	else:
		%LayerInfoBody.show()
		%ExpandLayerInfo.icon = get_theme_icon("CodeFoldDownArrow", "EditorIcons")


func _on_layer_tree_layer_moved(from: int, to: int) -> void:
	move_layer(from, to)


func _on_layer_tree_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if ResourceLoader.exists(item.get_meta('scene')):
		find_parent('EditorView').plugin_reference.get_editor_interface().open_scene_from_path(item.get_meta('scene'))
		find_parent('EditorView').plugin_reference.get_editor_interface().set_main_screen_editor("2D")


#region Helpers
####### HELPERS ################################################################

func clean_scene_name(file_path:String) -> String:
	return file_path.get_file().trim_suffix('.tscn').capitalize()

#endregion
