@tool
extends DialogicEditor

enum LayoutModes {Preset, Custom, None}

var layouts_info := {}
var customization_editor_info := {}


################################################################################
##						EDITOR REGISTERING
################################################################################
## Overwrite. Register to the editor manager in here.
func _register() -> void:
	editors_manager.register_simple_editor(self)
	alternative_text = "Change the look of the dialog in your game"


func _open(argument:Variant = null) -> void:
	%LayoutMode.select(DialogicUtil.get_project_setting('dialogic/layout/mode', 0))
	_on_layout_mode_item_selected(%LayoutMode.selected)
	%MakeCustomPanel.hide()


################################################################################
##							EDITOR FUNCTIONALITY
################################################################################
func _ready() -> void:
	for indexer in DialogicUtil.get_indexers():
		for layout in indexer._get_layout_scenes():
			layouts_info[layout['path']] = layout
			$ThemeList.add_item(layout)
	
	%ClearCustomization.icon = get_theme_icon("Remove", "EditorIcons")
	%MakeCustomButton.icon = get_theme_icon("Override", "EditorIcons")
	%CustomScenePicker.resource_icon = get_theme_icon("PlayScene", "EditorIcons")
	%CustomScenePicker.value_changed.connect(_on_custom_scene_picker_value_changed)
	%MakeCustomPanel.add_theme_stylebox_override('panel', get_theme_stylebox("Background", "EditorStyles"))
	get_theme_icon("CreateNewSceneFrom", "EditorIcons")
	get_theme_icon("Load", "EditorIcons")
	get_theme_icon("New", "EditorIcons")

	get_theme_icon("NodeInfo", "EditorIcons")
	get_theme_icon("Unlinked", "EditorIcons")
	
	await get_tree().process_frame
	get_parent().set_tab_title(get_index(), 'Layout')
	get_parent().set_tab_icon(get_index(), get_theme_icon("MatchCase", "EditorIcons"))
	#Alternative icon: get_theme_icon("MeshTexture", "EditorIcons")
	$ThemeList.active_theme_changed.connect(_on_active_theme_changed)



func _on_layout_mode_item_selected(index:int) -> void:
	ProjectSettings.set_setting('dialogic/layout/mode', index)
	ProjectSettings.save()
	match index:
		LayoutModes.Preset:
			if layouts_info.has(DialogicUtil.get_project_setting('dialogic/layout/layout_scene', DialogicUtil.get_default_layout())):
				%PresetCustomization.show()
				load_layout_scene_customization(DialogicUtil.get_project_setting('dialogic/layout/layout_scene', DialogicUtil.get_default_layout()))

			%CustomScene.hide()
			%NoScene.hide()
		LayoutModes.Custom:
			%CustomScene.show()
			%CustomScenePicker.set_value(DialogicUtil.get_project_setting('dialogic/layout/layout_scene', DialogicUtil.get_default_layout()))
			%NoScene.hide()
			%PresetCustomization.hide()
		LayoutModes.None:
			ProjectSettings.set_setting('dialogic/editor/layout/mode', 2)
			%CustomScene.hide()
			%NoScene.show()
			%PresetCustomization.hide()
	%MakeCustomPanel.hide()


func _on_custom_scene_picker_value_changed(property_name:String, value:String):
	ProjectSettings.set_setting('dialogic/layout/layout_scene', value)
	ProjectSettings.save()


func _on_active_theme_changed(custom_scene_path:String) -> void:
	load_layout_scene_customization(custom_scene_path)

################################################################################
##					SELECT PRESET
################################################################################

#await get_tree().process_frame

# Creo que es esto:
# load_layout_scene_customization(current_info.get('path', ''))


################################################################################
##				CREATE CUSTOM COPY FROM PRESET
################################################################################
func _on_make_custom_button_pressed() -> void:
	if !%MakeCustomPanel.visible:
		%MakeCustomButton.text = "Cancel Creation"
		%MakeCustomPanel.show()
	else:
		%MakeCustomButton.text = "Make Custom"
		%MakeCustomPanel.hide()


func _on_close_make_custom_button_pressed() -> void:
	%MakeCustomPanel.hide()
	%MakeCustomButton.text = "Make Custom"


func _on_create_custom_copy_pressed() -> void:
	find_parent("EditorView").godot_file_dialog(
		create_custom_copy, "*",
		EditorFileDialog.FILE_MODE_OPEN_DIR)


func create_custom_copy(folder_path:String) -> void:
	var current_preset_info :Dictionary = layouts_info[ProjectSettings.get_setting('dialogic/layout/layout_scene', DialogicUtil.get_default_layout())]
	var folder_to_copy : String = current_preset_info.get('folder_to_copy', null)
	if folder_to_copy == null:
		return
	var new_folder_name :String= 'Custom'+current_preset_info.get('name', 'unknown').capitalize().replace(' ', '')+"Layout"
	DirAccess.make_dir_absolute(folder_path.path_join(new_folder_name))
	for file in DialogicUtil.listdir(folder_to_copy, true, false, true):
		if file == current_preset_info.get('path', ''):
			var export_overrides:Dictionary = DialogicUtil.get_project_setting('dialogic/layout/export_overrides', {})
			var orig_scene :Node = load(file).instantiate()
			DialogicUtil.apply_scene_export_overrides(orig_scene, export_overrides)
			orig_scene._ready()
			var packed_scene := PackedScene.new()
			var result := packed_scene.pack(orig_scene)
			if result == OK:
				result = ResourceSaver.save(packed_scene, folder_path.path_join(new_folder_name).path_join('custom_'+file.get_file()))
				if result != OK:
					push_error("[Dialoigc] An error occurred while saving the scene to disk.")

		else:
			DirAccess.copy_absolute(
				file,
				folder_path.path_join(new_folder_name).path_join(file.get_file())
			)
	%MakeCustomPanel.hide()
	ProjectSettings.set_setting('dialogic/layout/layout_scene', folder_path.path_join(new_folder_name).path_join(current_preset_info['path'].get_file()))
	%LayoutMode.select(LayoutModes.Custom)
	_on_layout_mode_item_selected(LayoutModes.Custom)
	find_parent('EditorView').plugin_reference.get_editor_interface().get_resource_filesystem().scan()



################################################################################
##						PRESET CUSTOMIZATION
################################################################################
func load_layout_scene_customization(custom_scene_path:String = "") -> void:
	var scene :Node = null
	if !custom_scene_path.is_empty() and FileAccess.file_exists(custom_scene_path):
		scene = load(custom_scene_path).instantiate()
	else:
		scene = load(ProjectSettings.get_setting('dialogic/layout/layout_scene', DialogicUtil.get_default_layout())).instantiate()
	if !scene:
		return

	for child in %ExportsTabs.get_children():
		child.queue_free()

	var export_overrides :Dictionary = DialogicUtil.get_project_setting('dialogic/layout/export_overrides', {})
	var current_grid :GridContainer
	var current_hbox :HBoxContainer

	var label_bg_style = get_theme_stylebox("CanvasItemInfoOverlay", "EditorStyles").duplicate()
	label_bg_style.content_margin_left = 5
	label_bg_style.content_margin_right = 5
	label_bg_style.content_margin_top = 5
	
	var current_group_name := ""
	customization_editor_info = {}
	for i in scene.script.get_script_property_list():
		if i['usage'] & PROPERTY_USAGE_CATEGORY:
			continue

		if i['usage'] & PROPERTY_USAGE_GROUP or current_hbox == null:
			var main_scroll = ScrollContainer.new()
			main_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			current_hbox = HBoxContainer.new()
			current_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			current_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			main_scroll.add_child(current_hbox, true)
			main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
			main_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			%ExportsTabs.add_child(main_scroll, true)
			current_grid = null
			if i['usage'] & PROPERTY_USAGE_GROUP:
				%ExportsTabs.set_tab_title(main_scroll.get_index(), i['name'])
				continue
			else:
				%ExportsTabs.set_tab_title(main_scroll.get_index(), 'General')

		if i['usage'] & PROPERTY_USAGE_SUBGROUP:
			var v_scroll := ScrollContainer.new()
			v_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			v_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if current_hbox.get_child_count():
				current_hbox.add_child(VSeparator.new())
			current_hbox.add_child(v_scroll, true)
			var v_box := VBoxContainer.new()
			v_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v_scroll.add_child(v_box, true)
			var title_label := Label.new()
			title_label.text = i['name']
			title_label.add_theme_stylebox_override('normal', label_bg_style)
			title_label.size_flags_horizontal = SIZE_EXPAND_FILL
			v_box.add_child(title_label, true)
			current_grid = GridContainer.new()
			current_grid.columns = 3
			v_box.add_child(current_grid, true)
			current_group_name = i['name'].to_snake_case()

		if current_grid == null:
			var v_scroll := ScrollContainer.new()
			v_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			current_hbox.add_child(v_scroll, true)
			current_grid = GridContainer.new()
			current_grid.columns = 3
			v_scroll.add_child(current_grid, true)

		if i['usage'] & PROPERTY_USAGE_EDITOR:
			var label := Label.new()
			label.text = str(i['name'].trim_prefix(current_group_name)).capitalize()
			current_grid.add_child(label, true)

			var current_value = scene.get(i['name'])
			customization_editor_info[i['name']] = {}
			customization_editor_info[i['name']]['orig'] = current_value
			
			if export_overrides.has(i['name']):
				current_value = str_to_var(export_overrides[i['name']])
			
			var input :Node = DialogicUtil.setup_script_property_edit_node(
				i, current_value,
				{'bool':_on_export_bool_submitted, 'color':_on_export_color_submitted, 'enum':_on_export_int_enum_submitted,
				'int':_on_export_number_submitted, 'float':_on_export_number_submitted, 'file':_on_export_file_submitted,
				'string':_on_export_input_text_submitted, "string_enum": _on_export_string_enum_submitted})

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
	await get_tree().process_frame
	%ExportsTabs.set_tab_title(0, "General")


func set_export_override(property_name:String, value:String = "") -> void:
	var export_overrides:Dictionary = DialogicUtil.get_project_setting('dialogic/layout/export_overrides', {})
	if !value.is_empty():
		export_overrides[property_name] = value
		customization_editor_info[property_name]['reset'].disabled = false
	else:
		export_overrides.erase(property_name)
		customization_editor_info[property_name]['reset'].disabled = true

	ProjectSettings.set_setting('dialogic/layout/export_overrides', export_overrides)

func _on_export_override_reset(property_name:String) -> void:
	var export_overrides:Dictionary = DialogicUtil.get_project_setting('dialogic/layout/export_overrides', {})
	export_overrides.erase(property_name)
	ProjectSettings.set_setting('dialogic/layout/export_overrides', export_overrides)
	customization_editor_info[property_name]['reset'].disabled = true
	set_customization_value(property_name, customization_editor_info[property_name]['orig'])

func set_customization_value(property_name:String, value:Variant) -> void:
	var node : Node = customization_editor_info[property_name]['node']
	if node is CheckBox:
		node.pressed = value
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

func _on_export_input_text_submitted(text:String, property_name:String) -> void:
	set_export_override(property_name, var_to_str(text))

func _on_export_bool_submitted(value:bool, property_name:String) -> void:
	set_export_override(property_name, var_to_str(value))

func _on_export_color_submitted(color:Color, property_name:String) -> void:
	set_export_override(property_name, var_to_str(color))

func _on_export_int_enum_submitted(item:int, property_name:String) -> void:
	set_export_override(property_name, var_to_str(item))

func _on_export_number_submitted(value:float, property_name:String) -> void:
	set_export_override(property_name, var_to_str(value))

func _on_export_file_submitted(property_name:String, value:String) -> void:
	set_export_override(property_name, var_to_str(value))

func _on_export_string_enum_submitted(value:int, property_name:String, list:PackedStringArray):
	set_export_override(property_name, var_to_str(list[value]))

func _on_clear_customization_pressed():
	%CustomizationResetPopup.show()

func _on_customization_reset_popup_confirmed():
	ProjectSettings.set_setting('dialogic/layout/export_overrides', {})
	load_layout_scene_customization()
