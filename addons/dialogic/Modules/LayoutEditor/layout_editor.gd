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
	%LayoutMode.select(ProjectSettings.get_setting('dialogic/layout/mode', 0))
	_on_layout_mode_item_selected(%LayoutMode.selected)


################################################################################
##							EDITOR FUNCTIONALITY
################################################################################
func _ready() -> void:
	for indexer in DialogicUtil.get_indexers():
		for layout in indexer._get_layout_scenes():
			layouts_info[layout['path']] = layout
			%StyleList.add_item(layout)
	
	%CustomScenePicker.resource_icon = get_theme_icon("PlayScene", "EditorIcons")
	%CustomScenePicker.value_changed.connect(_on_custom_scene_picker_value_changed)
	get_theme_icon("CreateNewSceneFrom", "EditorIcons")
	get_theme_icon("Load", "EditorIcons")
	get_theme_icon("New", "EditorIcons")

	get_theme_icon("NodeInfo", "EditorIcons")
	get_theme_icon("Unlinked", "EditorIcons")
	
	await get_tree().process_frame
	get_parent().set_tab_title(get_index(), 'Styles')
	get_parent().set_tab_icon(get_index(), load(DialogicUtil.get_module_path('LayoutEditor').path_join("styles_icon.svg")))
	%StyleList.active_theme_changed.connect(_on_active_theme_changed)



func _on_layout_mode_item_selected(index:int) -> void:
	ProjectSettings.set_setting('dialogic/layout/mode', index)
	ProjectSettings.save()
	%CustomScene.hide()
	%NoScene.hide()
	%StyleList.hide()
	%PresetCustomization.hide()
	match index:
		LayoutModes.Preset:
			%PresetCustomization.show()
			%StyleList.show()
			if layouts_info.has(ProjectSettings.get_setting('dialogic/layout/layout_scene', DialogicUtil.get_default_layout())):
				load_layout_scene_customization(ProjectSettings.get_setting('dialogic/layout/layout_scene', DialogicUtil.get_default_layout()))
		LayoutModes.Custom:
			%CustomScene.show()
			%CustomScenePicker.set_value(ProjectSettings.get_setting('dialogic/layout/layout_scene', DialogicUtil.get_default_layout()))
		LayoutModes.None:
			ProjectSettings.set_setting('dialogic/layout/mode', 2)
			%NoScene.show()


func _on_custom_scene_picker_value_changed(property_name:String, value:String):
	ProjectSettings.set_setting('dialogic/layout/layout_scene', value)
	ProjectSettings.save()


func _on_active_theme_changed(custom_scene_path:String) -> void:
	load_layout_scene_customization(custom_scene_path)


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

	var export_overrides :Dictionary = ProjectSettings.get_setting('dialogic/layout/export_overrides', {})
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
				'string':_on_export_input_text_submitted, "string_enum": _on_export_string_enum_submitted, 'vector2':_on_export_vector_submitted})

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
	var export_overrides:Dictionary = ProjectSettings.get_setting('dialogic/layout/export_overrides', {})
	if str_to_var(value) != customization_editor_info[property_name]['orig']:
		export_overrides[property_name] = value
		customization_editor_info[property_name]['reset'].disabled = false
	else:
		export_overrides.erase(property_name)
		customization_editor_info[property_name]['reset'].disabled = true

	ProjectSettings.set_setting('dialogic/layout/export_overrides', export_overrides)
	ProjectSettings.save()


func _on_export_override_reset(property_name:String) -> void:
	var export_overrides:Dictionary = ProjectSettings.get_setting('dialogic/layout/export_overrides', {})
	export_overrides.erase(property_name)
	ProjectSettings.set_setting('dialogic/layout/export_overrides', export_overrides)
	customization_editor_info[property_name]['reset'].disabled = true
	set_customization_value(property_name, customization_editor_info[property_name]['orig'])
	ProjectSettings.save()


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

func _on_export_vector_submitted(property_name:String, value:Vector2) -> void:
	set_export_override(property_name, var_to_str(value))
