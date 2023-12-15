@tool
extends HSplitContainer

## Script that handles the style editor.


var current_style: DialogicStyle = null

var customization_editor_info := {}

## -1 is the base scene, 0 to n are the layers
var current_layer_idx := -1



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


func load_style(style:DialogicStyle) -> void:
	current_style = style

	if current_style.has_meta('_latest_layer'):
		current_layer_idx = current_style.get_meta('_latest_layer', -1)
	else:
		current_layer_idx = -1

	%AddLayerButton.disabled = style.inherits_anything()
	%ReplaceLayerButton.disabled = style.inherits_anything()
	%MakeCustomButton.disabled = style.inherits_anything()
	%DeleteLayerButton.disabled = style.inherits_anything()

	load_style_layer_list()


func load_style_layer_list() -> void:
	var tree: Tree = %LayerTree

	tree.clear()

	var root := tree.create_item()
	var base_scene := current_style.get_inheritance_root().get_base_scene().resource_path
	if %StyleBrowser.is_premade_style_part(base_scene):
		if ResourceLoader.exists(%StyleBrowser.premade_scenes_reference[base_scene].get('icon', '')):
			root.set_icon(0, load(%StyleBrowser.premade_scenes_reference[base_scene].get('icon')))
		root.set_text(0, %StyleBrowser.premade_scenes_reference[base_scene].get('name', 'Layer'))
	else:
		root.set_text(0, clean_scene_name(base_scene))
		root.add_button(0, get_theme_icon("PackedScene", "EditorIcons"))
		root.set_button_tooltip_text(0, 0, 'Open Scene')
	root.set_meta('scene', base_scene)

	for layer_scene in current_style.get_layer_list():
		var layer_item := tree.create_item(root)
		if %StyleBrowser.is_premade_style_part(layer_scene):
			if ResourceLoader.exists(%StyleBrowser.premade_scenes_reference[layer_scene].get('icon', '')):
				layer_item.set_icon(0, load(%StyleBrowser.premade_scenes_reference[layer_scene].get('icon')))

			layer_item.set_text(0, %StyleBrowser.premade_scenes_reference[layer_scene].get('name', 'Layer'))
		else:
			layer_item.set_text(0, clean_scene_name(layer_scene))
			layer_item.add_button(0, get_theme_icon("PackedScene", "EditorIcons"))
			layer_item.set_button_tooltip_text(0, 0, 'Open Scene')

		layer_item.set_meta('scene', layer_scene)

	if current_layer_idx == -1:
		root.select(0)
	else:
		root.get_child(current_layer_idx).select(0)


func _on_layer_selected() -> void:
	var item: TreeItem = %LayerTree.get_selected()
	if item == %LayerTree.get_root():
		load_layer(-1)
	else:
		load_layer(item.get_index())



func load_layer(layer_idx:=-1):
	current_layer_idx = layer_idx

	current_style.set_meta('_latest_layer', current_layer_idx)
	var layer_info := current_style.get_layer_inherited_info(layer_idx)

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

	%DeleteLayerButton.disabled = layer_idx == -1 or current_style.inherits_anything()

	%SmallLayerScene.text = layer_info.get('path', 'Unkown Layer').get_file()
	%SmallLayerScene.tooltip_text = layer_info.get('path', '')

	var inherited_layer_info := current_style.get_layer_inherited_info(layer_idx, true)
	load_layout_scene_customization(
			layer_info.path,
			layer_info.overrides,
			inherited_layer_info.overrides)


func add_layer(scene_path:="", overrides:= {}):
	current_style.add_layer(scene_path, overrides)
	load_style_layer_list()
	await get_tree().process_frame
	%LayerTree.get_root().get_child(-1).select(0)


func delete_layer():
	if current_layer_idx == -1:
		return
	current_style.delete_layer(current_layer_idx)
	load_style_layer_list()
	%LayerTree.get_root().select(0)


func move_layer(from_idx:int, to_idx:int) -> void:
	current_style.move_layer(from_idx, to_idx)
	load_style_layer_list()
	%LayerTree.get_root().get_child(to_idx).select(0)


func replace_layer(layer_index:int, scene_path:String) -> void:
	current_style.set_layer_scene(layer_index, scene_path)
	load_style_layer_list()

	if layer_index == -1:
		%LayerTree.get_root().select(0)
	else:
		%LayerTree.get_root().get_child(layer_index).select(0)


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
			if %LayerTree.get_selected() == %LayerTree.get_root():
				replace_layer(-1, picked_info.get('path', ''))
			elif %LayerTree.get_selected() != null:
				replace_layer(%LayerTree.get_selected().get_index(), picked_info.get('path', ''))

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
	if %LayerTree.get_selected() == %LayerTree.get_root():
		replace_layer(-1, file_path)
	elif %LayerTree.get_selected() != null:
		replace_layer(%LayerTree.get_selected().get_index(), file_path)



func _on_make_custom_button_about_to_popup() -> void:
	%MakeCustomButton.get_popup().set_item_disabled(2, false)
	%MakeCustomButton.get_popup().set_item_disabled(3, false)

	if not %StyleBrowser.is_premade_style_part(current_style.get_layer_info(current_layer_idx).path):
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
	if not ResourceLoader.exists(current_style.get_layer_info(current_layer_idx).path):
		printerr("[Dialogic] Unable to copy layer that has no scene path specified!")
		return

	var target_file := ""
	var previous_file: String = current_style.get_layer_info(current_layer_idx).path
	if custom_name.is_empty():
		target_file = 'custom_' + previous_file.get_file()
		target_folder = target_folder.path_join(%StyleBrowser.premade_scenes_reference[previous_file].name.to_pascal_case())
	else:
		if not custom_name.ends_with('.tscn'):
			custom_name += ".tscn"
		target_file = custom_name

	DirAccess.make_dir_absolute(target_folder)

	DirAccess.copy_absolute(previous_file, target_folder.path_join(target_file))

	var file := FileAccess.open(target_folder.path_join(target_file), FileAccess.READ)
	var scene_text := file.get_as_text()
	file.close()
	if scene_text.begins_with('[gd_scene'):
		var base_path: String = previous_file.get_base_dir()

		var result := RegEx.create_from_string("\\Q\""+base_path+"\\E(?<file>[^\"]*)\"").search(scene_text)
		while result:
			DirAccess.copy_absolute(base_path.path_join(result.get_string('file')), target_folder.path_join(result.get_string('file')))
			scene_text = scene_text.replace(base_path.path_join(result.get_string('file')), target_folder.path_join(result.get_string('file')))
			result = RegEx.create_from_string("\\Q\""+base_path+"\\E(?<file>[^\"]*)\"").search(scene_text)

	file = FileAccess.open(target_folder.path_join(target_file), FileAccess.WRITE)
	file.store_string(scene_text)
	file.close()

	current_style.set_layer_scene(current_layer_idx, target_folder.path_join(target_file))

	load_style_layer_list()

	if %LayerTree.get_selected() == %LayerTree.get_root():
		%LayerTree.get_root().select(0)
	else:
		%LayerTree.get_root().get_child(%LayerTree.get_selected().get_index()).select(0)

	find_parent('EditorView').plugin_reference.get_editor_interface().get_resource_filesystem().scan_sources()


func make_layout_custom(target_folder:String) -> void:
	target_folder = target_folder.path_join("Custom" + current_style.name.to_pascal_case())

	DirAccess.make_dir_absolute(target_folder)
	%LayerTree.get_root().select(0)
	make_layer_custom(target_folder, "custom_" + current_style.name.to_snake_case())


	var target_path := current_style.get_base_scene().resource_path

	# Load base scene
	var base_scene_pck: PackedScene = current_style.get_base_scene().duplicate()
	var base_scene := base_scene_pck.instantiate()
	base_scene.name = "Custom" + clean_scene_name(base_scene_pck.resource_path).to_pascal_case()

	# Load layers
	for layer_idx in range(current_style.get_layer_count()):
		var layer_info := current_style.get_layer_inherited_info(layer_idx)

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
	if !custom_scene_path.is_empty() and FileAccess.file_exists(custom_scene_path):
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

	var current_grid :GridContainer = null

	var label_bg_style = get_theme_stylebox("CanvasItemInfoOverlay", "EditorStyles").duplicate()
	label_bg_style.content_margin_left = 5
	label_bg_style.content_margin_right = 5
	label_bg_style.content_margin_top = 5

	var current_group_name := ""
	var current_subgroup_name := ""
	customization_editor_info = {}

	for i in settings:
		match i['id']:
			&"GROUP":
				var main_scroll = ScrollContainer.new()
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

				var scene_value = scene.get(i['name'])
				customization_editor_info[i['name']] = {}

				if i['name'] in inherited_overrides:
					customization_editor_info[i['name']]['orig'] = str_to_var(inherited_overrides.get(i['name']))
				else:
					customization_editor_info[i['name']]['orig'] = scene_value

				var current_value :Variant
				if i['name'] in overrides:
					current_value = str_to_var(overrides.get(i['name']))
				else:
					current_value = customization_editor_info[i['name']]['orig']

				var input :Node = DialogicUtil.setup_script_property_edit_node(i, current_value, set_export_override)

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
		if i['usage'] & PROPERTY_USAGE_CATEGORY:
			continue

		if (i['usage'] & PROPERTY_USAGE_GROUP):
			current_group = i
			current_group['added'] = false
			current_group['id'] = &'GROUP'
			current_subgroup = {}

		elif i['usage'] & PROPERTY_USAGE_SUBGROUP:
			current_subgroup = i
			current_subgroup['added'] = false
			current_subgroup['id'] = &'SUBGROUP'

		elif i['usage'] & PROPERTY_USAGE_EDITOR:
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
		current_style.set_layer_setting(current_layer_idx, property_name, value)
		customization_editor_info[property_name]['reset'].disabled = false
	else:
		current_style.remove_layer_setting(current_layer_idx, property_name)
		customization_editor_info[property_name]['reset'].disabled = true


func _on_export_override_reset(property_name:String) -> void:
	current_style.remove_layer_setting(current_layer_idx, property_name)
	customization_editor_info[property_name]['reset'].disabled = true
	set_customization_value(property_name, customization_editor_info[property_name]['orig'])


func set_customization_value(property_name:String, value:Variant) -> void:
	var node : Node = customization_editor_info[property_name]['node']
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
