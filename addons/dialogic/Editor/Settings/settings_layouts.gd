@tool
extends VBoxContainer

enum LayoutModes {Preset, Custom, None}
const default_layout_path := "res://addons/dialogic/Example Assets/example-scenes/DialogicDefaultScene.tscn"

var layouts_info := {}


func _ready() -> void:
	get_parent().set_tab_title(get_index(), 'Layout')
	for indexer in DialogicUtil.get_indexers():
		for layout in indexer._get_layout_scenes():
			layouts_info[layout['path']] = layout
	
	%ClearCustomization.icon = get_theme_icon("Remove", "EditorIcons")

func refresh() -> void:
	%LayoutMode.select(DialogicUtil.get_project_setting('dialogic/layout/mode', 0))
	_on_layout_mode_item_selected(%LayoutMode.selected)

func _on_layout_mode_item_selected(index:int) -> void:
	match index:
		LayoutModes.Preset:
			%PresetScene.show()
			%PresetSceneLabel.text = layouts_info.get(DialogicUtil.get_project_setting('dialogic/layout_scene', default_layout_path), {}).get('name', 'Invalid Preset!')
			%CustomScene.hide()
			%TestingScene.hide()
			%PresetCustomization.show()
			load_layout_scene_customization(DialogicUtil.get_project_setting('dialogic/layout_scene', default_layout_path))
		LayoutModes.Custom:
			%PresetScene.hide()
			%CustomScene.show()
			%CustomScenePicker.set_value(DialogicUtil.get_project_setting('dialogic/layout_scene', default_layout_path))
			%TestingScene.hide()
		LayoutModes.None:
			%PresetScene.hide()
			%CustomScene.hide()
			%TestingScene.show()
			%TestingScenePicker.set_value(DialogicUtil.get_project_setting('dialogic/editor/custom_testing_layout', default_layout_path))


func _on_preset_selection_pressed() -> void:
	%PresetSelection.show()
	%PresetCustomization.hide()
	update_presets_list()


func update_presets_list() -> void:
	%LayoutItemList.clear()
	
	var current_path :String = DialogicUtil.get_project_setting('dialogic/layout_scene', "res://addons/dialogic/Example Assets/example-scenes/DialogicDefaultScene.tscn")
	var index := 0
	for indexer in DialogicUtil.get_indexers():
		for layout in indexer._get_layout_scenes():
			var preview_image = null
			if layout.has('preview_image'):
				preview_image = load(layout.preview_image[0])
			else:
				preview_image = load("res://addons/dialogic/Editor/Images/Unknown.png")
			%LayoutItemList.add_item(layout.get('name', 'Mysterious Layout'), preview_image)
			if layout.get('path', '') == current_path:
				%LayoutItemList.set_item_custom_fg_color(index, get_theme_color("accent_color", "Editor"))
				%LayoutItemList.select(index)
			%LayoutItemList.set_item_metadata(index, layout)
			
			index += 1
	if %LayoutItemList.get_selected_items().is_empty(): %LayoutItemList.select(0)


func _on_layout_item_list_item_selected(index:int) -> void:
	display_preview(%LayoutItemList.get_item_metadata(index))


func display_preview(info:Dictionary, custom:=false) -> void:
	%PreviewTitle.text = info.get('name', 'Mysterious Layout (no name provided)')
	if info.has('preview_image'):
		%PreviewImage.texture = load(info.preview_image[0])
		%PreviewImage.show()
	else:
		%PreviewImage.texture = null
		%PreviewImage.hide()
	%PreviewDescription.text = info.get('description', '<No description provided>')


func get_selected_preset_info() -> Dictionary:
	return %LayoutItemList.get_item_metadata(%LayoutItemList.get_selected_items()[0])


func _on_activate_button_pressed() -> void:
	var current_info := get_selected_preset_info()
	ProjectSettings.set_setting('dialogic/layout_scene', current_info.get('path', ''))
	ProjectSettings.set_setting('dialogic/editor/custom_testing_layout', current_info.get('path', ''))
	ProjectSettings.save()
	%PresetSceneLabel.text = current_info.get('name', 'Mysterious Layout')
	%PresetSelection.hide()
	%PresetCustomization.show()
	load_layout_scene_customization(current_info.get('path', ''))



func load_layout_scene_customization(custom_scene_path:String = "") -> void:
	var scene :Node = null
	if custom_scene_path:
		scene = load(custom_scene_path).instantiate()
	else:
		scene = load(ProjectSettings.get_setting('dialogic/layout_scene', default_layout_path)).instantiate()
	if !scene:
		return
	
	for child in %ExportsTabs.get_children(): 
		child.queue_free()
	
	var export_overrides :Dictionary = DialogicUtil.get_project_setting('dialogic/layout/export_overrides', {})
	print(export_overrides)
	var current_grid :GridContainer
	var current_hbox :HBoxContainer
#	print(scene.get_property_list())
#	print("-------------------")
#	print(scene.script.get_script_property_list())
#	return
	
	# Setup of group
	var main_scroll = ScrollContainer.new()
	main_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	current_hbox = HBoxContainer.new()
	current_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_scroll.add_child(current_hbox, true)
	main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	%ExportsTabs.add_child(main_scroll, true)
	%ExportsTabs.set_tab_title(main_scroll.get_index(), "General") # i['name'] goes here
	
	# Setup of subgroup
	var v_scroll := ScrollContainer.new()
	v_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	current_hbox.add_child(v_scroll, true)
	var v_box := VBoxContainer.new()
	v_scroll.add_child(v_box, true)

	var title_label := Label.new()
	title_label.text = "General" # i['name'] goes here
	title_label.add_theme_stylebox_override('normal', get_theme_stylebox("CanvasItemInfoOverlay", "EditorStyles"))
	title_label.size_flags_horizontal = SIZE_EXPAND_FILL
	v_box.add_child(title_label, true)
	current_grid = GridContainer.new()
	current_grid.columns = 3
	v_box.add_child(current_grid, true)
#	current_grid = null
	for i in scene.script.get_script_property_list():
#		if i['usage'] & PROPERTY_USAGE_GROUP or i['usage'] & PROPERTY_USAGE_SUBGROUP:
#			print(i['name'])
#		if i['usage'] & PROPERTY_USAGE_SCRIPT_VARIABLE:
#			print(i['name'])
#		continue
#
#		if i['usage'] & PROPERTY_USAGE_CATEGORY:
#			continue
#
#		if i['usage'] & PROPERTY_USAGE_GROUP or %ExportsTabs.get_child_count() == 0:
#
#			continue
		
#		if i['usage'] & PROPERTY_USAGE_SUBGROUP:
#
#
#		if current_grid == null:
#			var v_scroll := ScrollContainer.new()
#			v_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
#			current_hbox.add_child(v_scroll, true)
#			current_grid = GridContainer.new()
#			current_grid.columns = 2
#			v_scroll.add_child(current_grid, true)
#
#
		if i['usage'] & PROPERTY_USAGE_EDITOR:
			print(i)
			var label := Label.new()
			label.text = str(i['name']).capitalize()
#			label.add_theme_stylebox_override('normal', get_theme_stylebox("CanvasItemInfoOverlay", "EditorStyles"))
#			label.size_flags_horizontal = SIZE_EXPAND_FILL
			current_grid.add_child(label, true)
			
			var input :Node = null
			var current_value = scene.get(i['name'])
			if export_overrides.has(i['name']):
				current_value = str_to_var(export_overrides[i['name']])
			match typeof(scene.get(i['name'])):
				TYPE_BOOL:
					input = CheckBox.new()
					if current_value:
						input.button_pressed = current_value == "true"
					input.toggled.connect(_on_export_bool_submitted.bind(i['name']))
				TYPE_COLOR:
					input = ColorPickerButton.new()
					if current_value:
						input.color = current_value
					input.color_changed.connect(_on_export_color_submitted.bind(i['name']))
					input.custom_minimum_size.x = DialogicUtil.get_editor_scale()*50
				TYPE_INT:
					if i['hint'] & PROPERTY_HINT_ENUM:
						input = OptionButton.new()
						for x in i['hint_string'].split(','):
							input.add_item(x.split(':')[0])
						if current_value:
							input.select(current_value)
						input.item_selected.connect(_on_export_int_enum_submitted.bind(i['name']))
					else:
						input = SpinBox.new()
						input.value_changed.connect(_on_export_int_submitted.bind(i['name']))
						input.step = 1
						if current_value:
							input.value = current_value
				_:
					input = LineEdit.new()
					if current_value:
						input.text = current_value
					input.text_submitted.connect(_on_export_input_text_submitted.bind(i['name']))
			input.size_flags_horizontal = SIZE_EXPAND_FILL
			current_grid.add_child(input)
			var reset := Button.new()
			reset.flat = true
			reset.icon = get_theme_icon('Clear', 'EditorIcons')
			current_grid.add_child(reset)
			reset.pressed.connect(_on_export_override_reset.bind(i['name']))
	await get_tree().process_frame
#	%ExportsTabs.print_tree_pretty()
	%ExportsTabs.set_tab_title(0, "General")


func set_export_override(property_name:String, value:String = "") -> void:
	var export_overrides:Dictionary = DialogicUtil.get_project_setting('dialogic/layout/export_overrides', {})
	if !value.is_empty():
		export_overrides[property_name] = value
	else:
		export_overrides.erase(property_name)
	
	ProjectSettings.set_setting('dialogic/layout/export_overrides', export_overrides)

func _on_export_override_reset(property_name:String) -> void:
	var export_overrides:Dictionary = DialogicUtil.get_project_setting('dialogic/layout/export_overrides', {})
	export_overrides.erase(property_name)
	ProjectSettings.set_setting('dialogic/layout/export_overrides', export_overrides)
	load_layout_scene_customization()

func _on_export_input_text_submitted(text:String, property_name:String) -> void:
	set_export_override(property_name, var_to_str(text))

func _on_export_bool_submitted(value:bool, property_name:String) -> void:
	set_export_override(property_name, var_to_str(value))

func _on_export_color_submitted(color:Color, property_name:String) -> void:
	set_export_override(property_name, var_to_str(color))

func _on_export_int_enum_submitted(item:int, property_name:String) -> void:
	set_export_override(property_name, var_to_str(item))

func _on_export_int_submitted(value:float, property_name:String) -> void:
	set_export_override(property_name, var_to_str(int(value)))


func _on_clear_customization_pressed():
	ProjectSettings.set_setting('dialogic/layout/export_overrides', {})
	load_layout_scene_customization()
