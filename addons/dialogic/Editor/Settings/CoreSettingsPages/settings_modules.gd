@tool
extends DialogicSettingsPage


func _get_title() -> String:
	return "Modules"

func _get_priority() -> int:
	return 0

func _is_feature_tab() -> bool:
	return true


func _ready() -> void:
	if get_parent() is SubViewport:
		return
	%Refresh.icon = get_theme_icon("Loop", "EditorIcons")
	%Search.right_icon = get_theme_icon("Search", "EditorIcons")

	%Filter_Events.icon = get_theme_icon("Favorites", "EditorIcons")
	%Filter_Subsystems.icon = get_theme_icon("Panels1", "EditorIcons")
	%Filter_Styles.icon = get_theme_icon("PopupMenu", "EditorIcons")
	%Filter_EffectsAndModifiers.icon = get_theme_icon("RichTextEffect", "EditorIcons")
	%Filter_Editors.icon = get_theme_icon("ConfirmationDialog", "EditorIcons")
	%Filter_Settings.icon = get_theme_icon("PluginScript", "EditorIcons")
	%Collapse.icon = get_theme_icon("CollapseTree", "EditorIcons")
	for i in %Filters.get_children():
		i.add_theme_color_override("icon_pressed_color", i.get_theme_color("font_pressed_color"))
		i.add_theme_color_override("icon_hover_color", i.get_theme_color("font_hover_color"))
		i.add_theme_color_override("icon_hover_pressed_color", i.get_theme_color("font_hover_pressed_color"))

	%ExternalLink.icon = get_theme_icon("Help", "EditorIcons")
	%ShowInFileSystem.icon = get_theme_icon("ShowInFileSystem", "EditorIcons")
	%Documentation.icon = get_theme_icon("Help", "EditorIcons")
	%Open.icon = get_theme_icon("Script", "EditorIcons")


func _refresh() -> void:
	%EventDefaultsPanel.hide()
	load_modules_tree()


func _on_refresh_pressed() -> void:
	DialogicUtil.get_indexers(true, true)
	DialogicResourceUtil.update_event_cache()
	load_modules_tree()


func _on_filter_toggled(toggled_on: bool, source: BaseButton) -> void:
	if Input.is_key_pressed(KEY_SHIFT):
		if not toggled_on:
			for button in %Filters.get_children():
				if button.button_pressed:
					toggled_on = true
					break
		for button in %Filters.get_children():
			if button != source:
				button.set_pressed_no_signal(not toggled_on)
			else:
				button.set_pressed_no_signal(toggled_on)
	load_modules_tree()



func _on_collapse_toggled(button_pressed:bool) -> void:
	for item in %Tree.get_root().get_children():
		item.collapsed = button_pressed

	if button_pressed:
		%Collapse.icon = get_theme_icon("ExpandTree", "EditorIcons")
		%Collapse.tooltip_text = "Expand All"
	else:
		%Collapse.icon = get_theme_icon("CollapseTree", "EditorIcons")
		%Collapse.tooltip_text = "Collapse All"


func _on_search_text_changed(new_text:String) -> void:
	for filter in %Filters.get_children():
		filter.text = ""
		filter.set_meta("counter", 0)

	for child in %Tree.get_root().get_children():
		if new_text.to_lower() in child.get_text(0).to_lower() or new_text.is_empty():
			for sub_child in child.get_children():
				sub_child.visible = sub_child.get_meta("filter_button").button_pressed
				sub_child.get_meta("filter_button").set_meta("counter", sub_child.get_meta("filter_button").get_meta("counter")+1)
				sub_child.get_meta("filter_button").text = str(sub_child.get_meta("filter_button").get_meta("counter"))
			child.visible = true
		else:
			for sub_child in child.get_children():
				sub_child.visible = sub_child.get_meta("filter_button").button_pressed and new_text.to_lower() in sub_child.get_text(0).to_lower()

				if new_text.to_lower() in sub_child.get_text(0).to_lower():
					sub_child.get_meta("filter_button").set_meta("counter", sub_child.get_meta("filter_button").get_meta("counter")+1)
					sub_child.get_meta("filter_button").text = str(sub_child.get_meta("filter_button").get_meta("counter"))

		for i in range(child.get_button_count(0)):
			child.erase_button(0, child.get_button_count(0)-1)
		var any_visible := false
		var counter := 0
		for sub_child in child.get_children():
			if sub_child.visible:
				child.add_button(0, sub_child.get_icon(0), counter, false, sub_child.get_text(0))
				if sub_child.get_metadata(0) and sub_child.get_metadata(0)["type"] == "Event" and sub_child.get_metadata(0)["hidden"]:
					var color: Color = sub_child.get_icon_modulate(0)
					color.a = 0.5
					child.set_button_color(0, counter, color)
				else:
					child.set_button_color(0, counter, sub_child.get_icon_modulate(0))
				counter += 1
				any_visible = true
		child.visible = any_visible


func load_modules_tree() -> void:
	%Tree.clear()
	var root: TreeItem = %Tree.create_item()
	var cached_events := DialogicResourceUtil.get_event_cache()
	var hidden_events: Array = DialogicUtil.get_editor_setting("hidden_event_buttons", DialogicUtil.SETTING_HIDDEN_BUTTONS_DEFAULT)

	var indexers := DialogicUtil.get_indexers()
	for i in indexers:
		var module_item: TreeItem = %Tree.create_item(root)
		module_item.set_text(0, i.get_script().resource_path.trim_suffix("/index.gd").get_file())
		module_item.set_metadata(0, {"type":"Module", "info":i})

		# Events
		for ev in i._get_events():
			if not ResourceLoader.exists(ev):
				continue
			var event_item: TreeItem = %Tree.create_item(module_item)
			event_item.set_icon(0, get_theme_icon("Favorites", "EditorIcons"))
			for cached_event in cached_events:
				if cached_event.get_script().resource_path == ev:
					event_item.set_text(0, cached_event.event_name + " Event")
					event_item.set_icon_modulate(0, cached_event.event_color)
					var is_hidden: bool = cached_event.event_name in hidden_events
					event_item.set_metadata(0, {"type":"Event", "event":cached_event, "hidden":is_hidden})
					event_item.add_button(0, get_theme_icon("GuiVisibilityVisible", "EditorIcons"), 0, false, "Toggle Event Button Visibility")
					if is_hidden:
						event_item.set_button(0, 0, get_theme_icon("GuiVisibilityHidden", "EditorIcons"))
			event_item.set_meta("filter_button", %Filter_Events)
			event_item.visible = %Filter_Events.button_pressed

		# Subsystems
		for subsys in i._get_subsystems():
			var subsys_item: TreeItem = %Tree.create_item(module_item)
			subsys_item.set_icon(0, get_theme_icon("Panels1", "EditorIcons"))
			subsys_item.set_text(0, subsys.name + " Subsystem")
			subsys_item.set_icon_modulate(0, get_theme_color("readonly_color", "Editor"))
			subsys_item.set_metadata(0, {"type":"Subsystem", "info":subsys})
			subsys_item.set_meta("filter_button", %Filter_Subsystems)
			subsys_item.visible = %Filter_Subsystems.button_pressed

		# Style scenes
		for style in i._get_layout_parts():
			var style_item: TreeItem = %Tree.create_item(module_item)
			style_item.set_icon(0, get_theme_icon("PopupMenu", "EditorIcons"))
			style_item.set_text(0, style.name)
			style_item.set_icon_modulate(0, get_theme_color("property_color_x", "Editor"))
			style_item.set_metadata(0, {"type":"Style", "info":style})
			style_item.set_meta("filter_button", %Filter_Styles)
			style_item.visible = %Filter_Styles.button_pressed

		# Text Effects
		for effect in i._get_text_effects():
			var effect_item: TreeItem = %Tree.create_item(module_item)
			effect_item.set_icon(0, get_theme_icon("RichTextEffect", "EditorIcons"))
			effect_item.set_text(0, "Text effect ["+effect.command+"]")
			effect_item.set_icon_modulate(0, get_theme_color("property_color_z", "Editor"))
			effect_item.set_metadata(0, {"type":"Effect", "info":effect})
			effect_item.set_meta("filter_button", %Filter_EffectsAndModifiers)
			effect_item.visible = %Filter_EffectsAndModifiers.button_pressed

		# Text Modifiers
		for mod in i._get_text_modifiers():
			var mod_item: TreeItem = %Tree.create_item(module_item)
			mod_item.set_icon(0, get_theme_icon("RichTextEffect", "EditorIcons"))
			mod_item.set_text(0, mod.method.capitalize())
			mod_item.set_icon_modulate(0, get_theme_color("property_color_z", "Editor"))
			mod_item.set_metadata(0, {"type":"Modifier", "info":mod})
			mod_item.set_meta("filter_button", %Filter_EffectsAndModifiers)
			mod_item.visible = %Filter_EffectsAndModifiers.button_pressed

		# Settings
		for settings in i._get_settings_pages():
			var settings_item: TreeItem = %Tree.create_item(module_item)
			settings_item.set_icon(0, get_theme_icon("PluginScript", "EditorIcons"))
			settings_item.set_text(0, module_item.get_text(0) + " Settings")
			settings_item.set_icon_modulate(0, get_theme_color("readonly_color", "Editor"))
			settings_item.set_metadata(0, {"type":"Settings", "info":settings})
			settings_item.set_meta("filter_button", %Filter_Settings)
			settings_item.visible = %Filter_Settings.button_pressed

		# Editors
		for editor in i._get_editors():
			var editor_item: TreeItem = %Tree.create_item(module_item)
			editor_item.set_icon(0, get_theme_icon("ConfirmationDialog", "EditorIcons"))
			editor_item.set_text(0, editor.get_file().trim_suffix(".tscn").capitalize())
			editor_item.set_icon_modulate(0, get_theme_color("readonly_color", "Editor"))
			editor_item.set_metadata(0, {"type":"Editor", "info":editor})
			editor_item.set_meta("filter_button", %Filter_Editors)
			editor_item.visible = %Filter_Editors.button_pressed

		module_item.collapsed = %Collapse.button_pressed

	_on_search_text_changed(%Search.text)
	if %Tree.get_root().get_child_count(): %Tree.set_selected(%Tree.get_root().get_child(0), 0)


func _on_tree_button_clicked(item:TreeItem, _column:int, id:int, _mouse_button_index:int) -> void:
	match item.get_metadata(0)["type"]:
		"Module":
			item.collapsed = false
			%Tree.set_selected(item.get_child(id), 0)
		"Event":
			# Visibility item clicked
			if id == 0:
				var meta: Dictionary= item.get_metadata(0)
				if meta["hidden"]:
					item.set_button(0, 0, get_theme_icon("GuiVisibilityVisible", "EditorIcons"))
					item.get_parent().set_button_color(0, item.get_index(), item.get_icon_modulate(0))
					if item == %Tree.get_selected():
						%VisibilityToggle.button_pressed = true
				else:
					item.set_button(0, 0, get_theme_icon("GuiVisibilityHidden", "EditorIcons"))
					var color: Color = item.get_icon_modulate(0)
					color.a = 0.5
					item.get_parent().set_button_color(0, item.get_index(), color)
					if item == %Tree.get_selected():
						%VisibilityToggle.button_pressed = false
				meta["hidden"] = !meta["hidden"]
				item.set_metadata(0, meta)
				change_event_visibility(meta["event"], not meta["hidden"])


func _on_tree_item_selected() -> void:
	var selected_item: TreeItem = %Tree.get_selected()

	var metadata: Variant = selected_item.get_metadata(0)

	%Title.text = selected_item.get_text(0)
	%EventDefaultsPanel.hide()
	%Icon.texture = null
	%ExternalLink.hide()
	%VisibilityToggle.hide()
	%ShowInFileSystem.disabled = false
	%Open.disabled = false

	if metadata is Dictionary:
		match metadata.type:
			"Event":
				%GeneralInfo.text = "Events can be used in timelines and do all kinds of things. They often interact with subsystems and dialogic nodes."

				if %EventDefaults.get_child_count():
					%EventDefaultsPanel.show()
				load_event_settings(metadata.event)

				if metadata.event.help_page_path:
					%ExternalLink.show()
					%ExternalLink.set_meta("url", metadata.event.help_page_path)
				%Icon.texture = metadata.event._get_icon()
				if not metadata.event.disable_editor_button:
					%VisibilityToggle.show()
					%VisibilityToggle.button_pressed = !metadata.event.event_name in DialogicUtil.get_editor_setting("hidden_event_buttons", DialogicUtil.SETTING_HIDDEN_BUTTONS_DEFAULT)
					if %VisibilityToggle.button_pressed:
						%VisibilityToggle.icon = get_theme_icon("GuiVisibilityVisible", "EditorIcons")
					else:
						%VisibilityToggle.icon = get_theme_icon("GuiVisibilityHidden", "EditorIcons")

			# -------------------------------------------------
			"Subsystem":
				%GeneralInfo.text = "Subsystems hold specialized functionality. They mostly manage communication between events and dialogic nodes. Often they provide handy methods that can be accessed by the user like this: Dialogic.Subsystem.a_method()."
			# -------------------------------------------------
			"Effect":
				%GeneralInfo.text = "Text effects can be used in text events. They will be executed once reached and can take a single argument."
				%ShowInFileSystem.disabled = true
				%Open.disabled = true
			# -------------------------------------------------
			"Modifier":
				%GeneralInfo.text = "Modifiers can modify text from text events before it is shown."
				%ShowInFileSystem.disabled = true
				%Open.disabled = true
			# -------------------------------------------------
			"Style":
				%GeneralInfo.text = "Style presets can be activated and modified in the Styles editor. They provide the design of the dialog interface in your game."
			# -------------------------------------------------
			"Editor":
				%GeneralInfo.text = "Editors provide a user interface for editing dialogic data."
			# -------------------------------------------------
			"Settings":
				%GeneralInfo.text = "Settings pages provide settings that are usually used by subsystems, events and dialogic nodes."
			"Module":
				%GeneralInfo.text = ""
				%Open.disabled = true
			# -------------------------------------------------
			_:
				%GeneralInfo.text = ""
				%ShowInFileSystem.disabled = true
				%Open.disabled = true
	if %Open.disabled == false:
		%Open.icon = get_theme_icon("CodeHighlighter", "EditorIcons") if get_element_path().ends_with(".gd") else get_theme_icon("PackedScene", "EditorIcons")
	%Documentation.disabled = not get_element_path().ends_with(".gd")

func _on_external_link_pressed() -> void:
	if %ExternalLink.has_meta("url"):
		OS.shell_open(%ExternalLink.get_meta("url"))


func change_event_visibility(event:DialogicEvent, visibility:bool) -> void:
	if event:
		var list: Array= DialogicUtil.get_editor_setting("hidden_event_buttons", DialogicUtil.SETTING_HIDDEN_BUTTONS_DEFAULT)
		if visibility:
			list.erase(event.event_name)
		else:
			list.append(event.event_name)
		DialogicUtil.set_editor_setting("hidden_event_buttons", list)
		force_event_button_list_update()


func _on_visibility_toggle_toggled(button_pressed:bool) -> void:
	change_event_visibility(%Tree.get_selected().get_metadata(0).event, button_pressed)

	if button_pressed:
		%VisibilityToggle.icon = get_theme_icon("GuiVisibilityVisible", "EditorIcons")
		%Tree.get_selected().set_button(0, 0, get_theme_icon("GuiVisibilityVisible", "EditorIcons"))
		%Tree.get_selected().get_parent().set_button_color(0, %Tree.get_selected().get_index(), %Tree.get_selected().get_icon_modulate(0))
	else:
		%VisibilityToggle.icon = get_theme_icon("GuiVisibilityHidden", "EditorIcons")
		%Tree.get_selected().set_button(0, 0, get_theme_icon("GuiVisibilityHidden", "EditorIcons"))
		var color: Color = %Tree.get_selected().get_icon_modulate(0)
		color.a = 0.5
		%Tree.get_selected().get_parent().set_button_color(0, %Tree.get_selected().get_index(), color)


func force_event_button_list_update() -> void:
	find_parent("EditorsManager").editors["Timeline"].node.get_node("%VisualEditor").load_event_buttons()


func _on_show_in_file_system_pressed() -> void:
	EditorInterface.get_file_system_dock().navigate_to_path(get_element_path())


func _on_documentation_pressed() -> void:
	EditorInterface.set_main_screen_editor("Script")
	var msg = get_element_path()
	#print(msg)
	var dir := EditorInterface.get_resource_filesystem().get_filesystem_path(msg.get_base_dir())
	var the_class_name := dir.get_file_script_class_name(dir.find_file_index(msg.get_file()))
	#print(the_class_name)
	if the_class_name:
		EditorInterface.get_script_editor().goto_help("class_name:"+the_class_name)
		return
	#if msg.contains("/"):
		#msg='"'+msg.replace("res://","").replace('"',"").replace("'","")+'"'
	#msg='class'+'_name:'+msg.replace('class'+'_name:',"")
	##print(msg)
	#EditorInterface.get_script_editor().get_current_editor().go_to_help.emit(msg)
	#print('class_name:"'+get_element_path().trim_prefix("res://")+'"')
	EditorInterface.get_script_editor().goto_help('class_name:"'+get_element_path().trim_prefix("res://")+'"')


func _on_open_pressed() -> void:
	var path := get_element_path()
	if path.ends_with(".gd"):
		EditorInterface.set_main_screen_editor("Script")
		EditorInterface.edit_script(load(path), 1, 1)
	elif path.ends_with(".tscn"):
		EditorInterface.open_scene_from_path(path)
		await get_tree().process_frame
		EditorInterface.set_main_screen_editor("2D")


func get_element_path() -> String:
	var selected_item: TreeItem = %Tree.get_selected()
	var metadata: Variant = selected_item.get_metadata(0)
	if metadata is Dictionary:
		match metadata.type:
			"Module":
				return metadata.info.this_folder
			"Subsystem":
				return metadata.info.script
			"Event":
				return metadata.event.script.resource_path
			"Style":
				return metadata.info.path
			"Settings":
				return metadata.info
	return ""

#region EVENT DEFAULT SETTINGS
################################################################################

var customization_editor_info := {}

func load_event_settings(event:DialogicEvent) -> void:
	for child in %EventDefaults.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()

	customization_editor_info.clear()

	var event_default_overrides: Dictionary = ProjectSettings.get_setting("dialogic/event_default_overrides", {})

	var params := event.get_shortcode_parameters()
	var property_list := event.get_property_list()
	for prop in params:
		var orig_value : Variant = params[prop].default
		var current_value: Variant = orig_value
		var prop_name: String = params[prop].property

		if event_default_overrides.get(event.event_name, {}).has(prop_name):
			current_value = event_default_overrides.get(event.event_name, {}).get(prop_name)

		customization_editor_info[prop_name] = {"orig":orig_value, "current":current_value}

		# Label
		var label := Label.new()
		label.text = prop.capitalize()
		%EventDefaults.add_child(label)

		var reset := Button.new()
		reset.flat = true
		reset.icon = get_theme_icon("Reload", "EditorIcons")
		reset.tooltip_text = "Remove customization"
		reset.pressed.connect(_on_export_override_reset.bind(prop_name))
		reset.disabled = typeof(current_value) == typeof(orig_value) and current_value == orig_value
		customization_editor_info[prop_name]["reset"] = reset
		%EventDefaults.add_child(reset)

		# Editing field
		var editor_node: Node = DialogicUtil.setup_script_property_edit_node(
			property_list.filter(func(x): return x.name == prop_name)[0], current_value, set_event_default_override)
		editor_node.size_flags_horizontal = SIZE_EXPAND_FILL
		customization_editor_info[prop_name]["node"] = editor_node
		%EventDefaults.add_child(editor_node)

	%EventDefaultsPanel.visible = %EventDefaults.get_child_count() > 0


func set_event_default_override(prop:String, value:Variant) -> void:
	value = str_to_var(value)
	var event_default_overrides: Dictionary = ProjectSettings.get_setting("dialogic/event_default_overrides", {})
	var event: DialogicEvent = %Tree.get_selected().get_metadata(0).event

	if not event_default_overrides.has(event.event_name):
		event_default_overrides[event.event_name] = {}

	if value == customization_editor_info[prop].orig:
		event_default_overrides[event.event_name].erase(prop)
		customization_editor_info[prop].reset.disabled = true
	else:
		event_default_overrides[event.event_name][prop] = value
		customization_editor_info[prop].reset.disabled = false

	ProjectSettings.set_setting("dialogic/event_default_overrides", event_default_overrides)


func _on_export_override_reset(property_name:String) -> void:
	var event_default_overrides: Dictionary = ProjectSettings.get_setting("dialogic/event_default_overrides", {})
	var event: DialogicEvent = %Tree.get_selected().get_metadata(0).event
	if event.event_name in event_default_overrides:
		event_default_overrides[event.event_name].erase(property_name)
		#current_style.remove_layer_setting(current_layer_id, property_name)
		print(customization_editor_info.keys())
		customization_editor_info[property_name]["reset"].disabled = true
		set_customization_value(property_name, customization_editor_info[property_name]["orig"])


func set_customization_value(property_name:String, value:Variant) -> void:
	var node: Node = customization_editor_info[property_name]["node"]
	if node is CheckBox:
		node.button_pressed = value
	elif node is LineEdit:
		node.text = value
	elif node.has_method("set_value"):
		node.set_value(value)
	elif node is ColorPickerButton:
		node.color = value
	elif node is OptionButton:
		node.select(value)
	elif node is SpinBox:
		node.value = value


#endregion
