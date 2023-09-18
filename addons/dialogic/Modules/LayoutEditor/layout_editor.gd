@tool
extends DialogicEditor

#enum LayoutModes {PRESET, CUSTOM, NONE}

var style_list := {}
var default_style := ""

var preset_info := {}
var customization_editor_info := {}

# the current style-configuration
var current_style := ""
# the layout scene path of the current style-configuration
var current_layout := ""


################################################################################
##						EDITOR REGISTERING
################################################################################

func _get_title() -> String:
	return "Styles"


func _get_icon() -> Texture:
	return load(DialogicUtil.get_module_path('LayoutEditor').path_join("styles_icon.svg"))


## Overwrite. Register to the editor manager in here.
func _register() -> void:
	editors_manager.register_simple_editor(self)
	alternative_text = "Change the look of the dialog in your game"


func _open(argument:Variant = null) -> void:
	pass


##					STYLE LIST FUNCTIONALITY
################################################################################
func _ready() -> void:
	for indexer in DialogicUtil.get_indexers():
		for layout in indexer._get_layout_scenes():
			preset_info[layout['path']] = layout
	style_list = ProjectSettings.get_setting('dialogic/layout/styles', {'Default':{}})
	default_style = ProjectSettings.get_setting('dialogic/layout/default_style', 'Default')
	%AddButton.icon = get_theme_icon("Add", "EditorIcons")
	%DuplicateButton.icon = get_theme_icon("Duplicate", "EditorIcons")
	%InheritButton.icon = get_theme_icon("Filesystem", "EditorIcons")
	%RemoveButton.icon = get_theme_icon("Remove", "EditorIcons")
	
	%StyleList.item_selected.connect(_on_style_clicked)
	
	
	%EditNameButton.icon = get_theme_icon("Edit", "EditorIcons")
	%TestStyleButton.icon = get_theme_icon("PlayCustom", "EditorIcons")
	%MakeDefaultButton.icon = get_theme_icon("Favorites", "EditorIcons")
	
	%InheritancePicker.resource_icon = get_theme_icon("Filesystem", "EditorIcons")
	%InheritancePicker.get_suggestions_func = get_inheritance_suggestions
	%InheritancePicker.force_string = true
	%ChangeLayoutButton.icon = get_theme_icon("Loop", "EditorIcons")
	
	%RealizeInheritance.icon = get_theme_icon("Unlinked", "EditorIcons")
	%ClearSettingsButton.icon = get_theme_icon("RotateLeft", "EditorIcons")
	
	
	load_style_list()


func save():
	ProjectSettings.set_setting('dialogic/layout/styles', style_list)
	ProjectSettings.set_setting('dialogic/layout/default_style', default_style)
	ProjectSettings.save()


func load_style_list() -> void:
	var latest := DialogicUtil.get_editor_setting('latest_layout_style', 'Default')
	%StyleList.clear()
	var sorted_keys := style_list.keys()
	sorted_keys.sort()
	for style_name in sorted_keys:
		%StyleList.add_item(style_name, get_theme_icon("PopupMenu", "EditorIcons"))
		if style_name == default_style:
			%StyleList.set_item_icon_modulate(%StyleList.item_count-1, get_theme_color("warning_color", "Editor"))
		if style_name == latest:
			%StyleList.select(%StyleList.item_count-1)
			_on_style_clicked(%StyleList.item_count-1)
	if !%StyleList.is_anything_selected():
		%StyleList.select(0)
		_on_style_clicked(0)


func _on_style_clicked(idx:int) -> void:
	load_style(%StyleList.get_item_text(idx))
	%RemoveButton.disabled = %StyleList.get_item_text(idx) == default_style


func _get_new_name(base_name:String) -> String:
	var new_name_idx := 2
	while base_name in style_list:
		base_name = base_name+" "+str(new_name_idx)
		new_name_idx += 1
	return base_name


func _on_add_button_pressed():
	var undo_redo :EditorUndoRedoManager= DialogicUtil.get_dialogic_plugin().get_undo_redo()
	undo_redo.create_action('Add Style', UndoRedo.MERGE_ALL)
	undo_redo.add_do_method(self, "add_style", _get_new_name('New Style'), )
	undo_redo.add_undo_method(self, "remove_style", _get_new_name('New Style'))
	undo_redo.commit_action()


func add_style(style_name:String, style_info:={}) -> void:
	style_list[style_name] = style_info
	DialogicUtil.set_editor_setting('latest_layout_style', style_name)
	save()
	load_style_list()


func remove_style(style_name:String) -> void:
	for style in style_list:
		if style_list[style].get('inherits', '') == style_name:
			realize_style_inheritance(style)
			push_warning('[Dialogic] Style "',style,'" had to be realized because it inherited "', style_name,'" which was deleted!')
	style_list.erase(style_name)
	save()
	load_style_list()


func _on_duplicate_button_pressed():
	if !%StyleList.is_anything_selected():
		return
	var undo_redo :EditorUndoRedoManager= DialogicUtil.get_dialogic_plugin().get_undo_redo()
	undo_redo.create_action('Add Style', UndoRedo.MERGE_ALL)
	undo_redo.add_do_method(self, "add_style", _get_new_name(current_style+' Copy'), style_list[current_style].duplicate(true))
	undo_redo.add_undo_method(self, "remove_style", _get_new_name(current_style+' Copy'))
	undo_redo.commit_action()


func _on_inherit_button_pressed():
	if !%StyleList.is_anything_selected():
		return
	var undo_redo :EditorUndoRedoManager= DialogicUtil.get_dialogic_plugin().get_undo_redo()
	undo_redo.create_action('Add Style', UndoRedo.MERGE_ALL)
	undo_redo.add_do_method(self, "add_style", _get_new_name(current_style+' SubStyle'), {'inherits':current_style})
	undo_redo.add_undo_method(self, "remove_style", _get_new_name(current_style+' SubStyle'))
	undo_redo.commit_action()


func _on_remove_button_pressed():
	if !%StyleList.is_anything_selected():
		return
	
	if current_style == default_style:
		push_warning("[Dialogic] You cannot delete the default style!")
		return
	
	var undo_redo :EditorUndoRedoManager= DialogicUtil.get_dialogic_plugin().get_undo_redo()
	undo_redo.create_action('Remove Style', UndoRedo.MERGE_ALL)
	undo_redo.add_do_method(self, "remove_style", current_style)
	undo_redo.add_undo_method(self, "add_style", current_style, style_list[current_style])
	undo_redo.commit_action()


func _on_edit_name_button_pressed():
	%LayoutStyleName.grab_focus()
	%LayoutStyleName.select_all()


func _on_layout_style_name_text_submitted(new_text:String) -> void:
	_on_layout_style_name_focus_exited()


func _on_layout_style_name_focus_exited():
	var new_name :String= %LayoutStyleName.text.strip_edges()
	if new_name in style_list:
		%LayoutStyleName.text = current_style
		return
	
	if current_style == default_style:
		default_style = new_name
	for style in style_list:
		if style_list[style].get('inherits', '') == current_style:
			style_list[style]['inherits'] = new_name
	style_list[new_name] = style_list[current_style].duplicate(true)
	style_list.erase(current_style)
	DialogicUtil.set_editor_setting('latest_layout_style', new_name)
	save()
	load_style_list()


func _on_make_default_button_pressed():
	default_style = current_style
	save()
	load_style_list()


func _on_test_style_button_pressed():
	var dialogic_plugin = DialogicUtil.get_dialogic_plugin()
	
	# Save the current opened timeline
	DialogicUtil.set_editor_setting('current_test_style', current_style)
	
	DialogicUtil.get_dialogic_plugin().get_editor_interface().play_custom_scene("res://addons/dialogic/Editor/TimelineEditor/test_timeline_scene.tscn")
	await get_tree().create_timer(3).timeout
	DialogicUtil.set_editor_setting('current_test_style', '')

##				STYLE SETTINGS FUNCTIONALITY
################################################################################

func load_style(style_name:String) -> void:
	current_style = style_name
	%LayoutStyleName.text = style_name
	
	if current_style == default_style:
		%MakeDefaultButton.tooltip_text = "Is Default"
		%MakeDefaultButton.disabled = true
	else:
		%MakeDefaultButton.tooltip_text = "Make Default"
		%MakeDefaultButton.disabled = false
	
	var info :Dictionary= style_list.get(style_name, {})
	
	%InheritancePicker.set_value(info.get('inherits',''))
	# this will also set the layout and load the layout's settings
	set_inheritance(info.get('inherits',''))
	
	DialogicUtil.set_editor_setting('latest_layout_style', style_name)
	%LayoutSelection.hide()
	%StyleSettings.show()


func get_inheritance_suggestions(filter:String="") -> Dictionary:
	var suggestions := {}
	suggestions['Nothing (Base Style)'] = {'value':'', 'icon':get_theme_icon("GuiRadioUnchecked", "EditorIcons")}
	for i in style_list:
		if current_style in DialogicUtil.get_inheritance_style_list(i) or current_style == i:
			continue
		suggestions[i] = {'value':i, 'icon': get_theme_icon("PopupMenu", "EditorIcons")}
	return suggestions


func _on_inheritance_picker_value_changed(property_name:String, value:Variant) -> void:
	style_list[current_style]['inherits'] = value
	set_inheritance(value)
	save()


func set_inheritance(value:String) -> void:
	var layout :String = style_list[current_style].get('layout', DialogicUtil.get_default_layout_scene())
	%ChangeLayoutButton.disabled = !value.is_empty()
	if !value.is_empty():
		%RealizeInheritance.show()
		layout = DialogicUtil.get_inherited_style_layout(current_style)
		%InheritanceChain.text = ""
		for i in DialogicUtil.get_inheritance_style_list(current_style):
			%InheritanceChain.text += '<'+i
		%InheritanceChain.text = %InheritanceChain.text.trim_prefix('<')
		%InheritanceChain.show()
		%ChangeLayoutButton.tooltip_text = "This layout is determined by inheritance."
	else:
		%RealizeInheritance.hide()
		%InheritanceChain.hide()
		%ChangeLayoutButton.tooltip_text = "Choose a preset or custom scene"
	set_layout(layout, true)
	load_layout_scene_customization(layout, style_list[current_style].get('export_overrides', {}), DialogicUtil.get_inherited_style_overrides(style_list[current_style].get('inherits', '')))


func _on_realize_inheritance_pressed() -> void:
	realize_style_inheritance(current_layout)
	save()
	load_style(current_style)


func realize_style_inheritance(style_name:String) -> void:
	style_list[style_name]['export_overrides'] = DialogicUtil.get_inherited_style_overrides(style_name)
	style_list[style_name]['layout'] = DialogicUtil.get_inherited_style_layout(style_name)
	style_list[style_name]['inherits'] = ""


func set_layout(path:String, just_load:=false,) -> void:
	var inherited :bool = !style_list[current_style].get('inherits', '').is_empty() 
	if inherited:
		%SceneImage.custom_minimum_size = Vector2(0, 50)*DialogicUtil.get_editor_scale()
		%SceneImage.modulate = Color(0.77083951234818, 0.77083945274353, 0.77083945274353)
	else:
		%SceneImage.modulate = Color.WHITE
		%SceneImage.custom_minimum_size = Vector2(0, 100)*DialogicUtil.get_editor_scale()
	%ChangeLayoutButton.visible = !inherited
	%SceneAuthor.visible = !inherited
	%InheritedIndicator.visible = inherited
	
	if path in preset_info:
		%SceneName.text = preset_info[path].name
		%SceneAuthor.text = preset_info[path].author
		%SceneImage.texture = load(preset_info[path].preview_image[0])
	else:
		%SceneName.text = path.get_file().trim_suffix('.'+path.get_extension())
		%SceneAuthor.text = "Custom Scene"
		DialogicUtil.get_dialogic_plugin().get_editor_interface().get_resource_previewer().queue_resource_preview(path, self, 'set_scene_preview', null)
	
	if !just_load and path != current_layout:
		load_layout_scene_customization(path)
		style_list[current_style]['layout'] = path
		save()
	current_layout = path


func set_scene_preview(path:String, preview:Texture2D, thumbnail:Texture2D, userdata:Variant) -> void:
	if preview:
		%SceneImage.texture = preview
	else:
		%SceneImage.texture = get_theme_icon("PackedScene", "EditorIcons")
	


func _on_change_layout_button_pressed():
	open_layout_selection()



func open_layout_selection() -> void:
	%StyleSettings.hide()
	%LayoutSelection.open(current_layout)


################################################################################
##						PRESET CUSTOMIZATION
################################################################################
func load_layout_scene_customization(custom_scene_path:String, own_overrides:Dictionary = {}, inherited_overrides:Dictionary = {}) -> void:
	for child in %ExportsTabs.get_children():
		child.queue_free()
	
	var scene :Node = null
	if !custom_scene_path.is_empty() and FileAccess.file_exists(custom_scene_path):
		var pck_scn := load(custom_scene_path)
		if pck_scn:
			scene = pck_scn.instantiate()
	
	if scene and scene.script:
		if own_overrides.is_empty():
			own_overrides = style_list[current_style].get('export_overrides', {})

		var current_grid :GridContainer = null
		var current_hbox :HBoxContainer = null

		var label_bg_style = get_theme_stylebox("CanvasItemInfoOverlay", "EditorStyles").duplicate()
		label_bg_style.content_margin_left = 5
		label_bg_style.content_margin_right = 5
		label_bg_style.content_margin_top = 5
		
		
		var current_group_name := ""
		customization_editor_info = {}
		for i in scene.script.get_script_property_list():
			if i['usage'] & PROPERTY_USAGE_CATEGORY:
				continue
			
			if (i['usage'] & PROPERTY_USAGE_GROUP) or current_hbox == null:
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
				title_label.theme_type_variation = "DialogicSection"
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

				var scene_value = scene.get(i['name'])
				customization_editor_info[i['name']] = {}
				
				if i['name'] in inherited_overrides:
					customization_editor_info[i['name']]['orig'] = str_to_var(inherited_overrides.get(i['name']))
				else:
					customization_editor_info[i['name']]['orig'] = scene_value
				
				var current_value :Variant
				if i['name'] in own_overrides:
					current_value = str_to_var(own_overrides.get(i['name']))
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
	
	await get_tree().process_frame
	if %ExportsTabs.get_child_count() == 0:
		var note := Label.new()
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.text = "This layout has no exposed settings.\n\nIf this is a custom scene and you want to add settings, make sure to have a root script in @tool mode if you want @exported variables to show up here."
		note.theme_type_variation = 'DialogicHintText2'
		%ExportsTabs.add_child(note)
	%ExportsTabs.set_tab_title(0, "General")


func _on_clear_settings_button_pressed():
	style_list[current_style]['export_overrides'] = {}
	save()
	load_style(current_style)


func set_export_override(property_name:String, value:String = "") -> void:
	var export_overrides:Dictionary = style_list[current_style].get('export_overrides', {})
	if str_to_var(value) != customization_editor_info[property_name]['orig']:
		export_overrides[property_name] = value
		customization_editor_info[property_name]['reset'].disabled = false
	else:
		export_overrides.erase(property_name)
		customization_editor_info[property_name]['reset'].disabled = true
	
	style_list[current_style]['export_overrides'] = export_overrides
	save()

func _on_export_override_reset(property_name:String) -> void:
	var export_overrides:Dictionary = style_list[current_style].get('export_overrides', {})
	export_overrides.erase(property_name)
	style_list[current_style]['export_overrides'] = export_overrides
	save()
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




