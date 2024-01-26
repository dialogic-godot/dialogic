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
	%Filter_Subsystems.icon = get_theme_icon("Callable", "EditorIcons")
	%Filter_Styles.icon = get_theme_icon("PopupMenu", "EditorIcons")
	%Filter_EffectsAndModifiers.icon = get_theme_icon("RichTextEffect", "EditorIcons")
	%Filter_Editors.icon = get_theme_icon("ConfirmationDialog", "EditorIcons")
	%Filter_Settings.icon = get_theme_icon("PluginScript", "EditorIcons")
	%Collapse.icon = get_theme_icon("CollapseTree", "EditorIcons")

	%EventDefaultsPanel.add_theme_stylebox_override('panel', get_theme_stylebox("Background", "EditorStyles"))

	%ExternalLink.icon = get_theme_icon("Help", "EditorIcons")


func _refresh() -> void:
	%EventDefaultsPanel.hide()
	load_modules_tree()


func _on_refresh_pressed() -> void:
	load_modules_tree()


func filters_updated(fake_arg:Variant) -> void:
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
	for filter in [%Filter_Events, %Filter_Subsystems, %Filter_Editors, %Filter_EffectsAndModifiers, %Filter_Settings, %Filter_Styles]:
		filter.text = ""
		filter.set_meta("counter", 0)

	var hidden_events :Array= DialogicUtil.get_editor_setting('hidden_event_buttons', [])

	for child in %Tree.get_root().get_children():
		if new_text.to_lower() in child.get_text(0).to_lower() or new_text.is_empty():
			for sub_child in child.get_children():
				sub_child.visible = sub_child.get_meta('filter_button').button_pressed
				sub_child.get_meta('filter_button').set_meta('counter', sub_child.get_meta('filter_button').get_meta('counter')+1)
				sub_child.get_meta('filter_button').text = str(sub_child.get_meta('filter_button').get_meta('counter'))
			child.visible = true
		else:
			for sub_child in child.get_children():
				sub_child.visible = sub_child.get_meta('filter_button').button_pressed and new_text.to_lower() in sub_child.get_text(0).to_lower()

				if new_text.to_lower() in sub_child.get_text(0).to_lower():
					sub_child.get_meta('filter_button').set_meta('counter', sub_child.get_meta('filter_button').get_meta('counter')+1)
					sub_child.get_meta('filter_button').text = str(sub_child.get_meta('filter_button').get_meta('counter'))

		for i in range(child.get_button_count(0)):
			child.erase_button(0, child.get_button_count(0)-1)
		var any_visible := false
		var counter := 0
		for sub_child in child.get_children():
			if sub_child.visible:
				child.add_button(0, sub_child.get_icon(0), counter, false, sub_child.get_text(0))
				if sub_child.get_metadata(0) and sub_child.get_metadata(0)['type'] == 'Event' and sub_child.get_metadata(0)['hidden']:
					var color : Color = sub_child.get_icon_modulate(0)
					color.a = 0.5
					child.set_button_color(0, counter, color)
				else:
					child.set_button_color(0, counter, sub_child.get_icon_modulate(0))
				counter += 1
				any_visible = true
		child.visible = any_visible



func load_modules_tree() -> void:
	%Tree.clear()
	var root :TreeItem = %Tree.create_item()
	var cached_events := DialogicResourceUtil.get_event_cache()
	var hidden_events: Array = DialogicUtil.get_editor_setting('hidden_event_buttons', [])
	var indexers := DialogicUtil.get_indexers()
	for i in indexers:
		var module_item :TreeItem = %Tree.create_item(root)
		module_item.set_text(0, i.get_script().resource_path.trim_suffix('/index.gd').get_file())
		module_item.set_metadata(0, {'type':'Module'})

		# Events
		for ev in i._get_events():
			if not FileAccess.file_exists(ev):
				continue
			var event_item : TreeItem = %Tree.create_item(module_item)
			event_item.set_icon(0, get_theme_icon("Favorites", "EditorIcons"))
			for cached_event in cached_events:
				if cached_event.get_script().resource_path == ev:
					event_item.set_text(0, cached_event.event_name + " Event")
					event_item.set_icon_modulate(0, cached_event.event_color)
					var hidden :bool = cached_event.event_name in hidden_events
					event_item.set_metadata(0, {'type':'Event', 'event':cached_event, 'hidden':hidden})
					event_item.add_button(0, get_theme_icon("GuiVisibilityVisible", "EditorIcons"), 0, false, "Toggle Event Button Visibility")
					if hidden:
						event_item.set_button(0, 0, get_theme_icon("GuiVisibilityHidden", "EditorIcons"))
			event_item.set_meta('filter_button', %Filter_Events)
			event_item.visible = %Filter_Events.button_pressed

		# Subsystems
		for subsys in i._get_subsystems():
			var subsys_item : TreeItem = %Tree.create_item(module_item)
			subsys_item.set_icon(0, get_theme_icon("Callable", "EditorIcons"))
			subsys_item.set_text(0, subsys.name + " Subsystem")
			subsys_item.set_icon_modulate(0, get_theme_color("readonly_color", "Editor"))
			subsys_item.set_metadata(0, {'type':'Subsystem', 'info':subsys})
			subsys_item.set_meta('filter_button', %Filter_Subsystems)
			subsys_item.visible = %Filter_Subsystems.button_pressed

		# Style scenes
		for style in i._get_layout_parts():
			var style_item : TreeItem = %Tree.create_item(module_item)
			style_item.set_icon(0, get_theme_icon("PopupMenu", "EditorIcons"))
			style_item.set_text(0, style.name)
			style_item.set_icon_modulate(0, get_theme_color("property_color_x", "Editor"))
			style_item.set_metadata(0, {'type':'Style', 'info':style})
			style_item.set_meta('filter_button', %Filter_Styles)
			style_item.visible = %Filter_Styles.button_pressed

		# Text Effects
		for effect in i._get_text_effects():
			var effect_item : TreeItem = %Tree.create_item(module_item)
			effect_item.set_icon(0, get_theme_icon("RichTextEffect", "EditorIcons"))
			effect_item.set_text(0, "Text effect ["+effect.command+"]")
			effect_item.set_icon_modulate(0, get_theme_color("property_color_z", "Editor"))
			effect_item.set_metadata(0, {'type':'Effect', 'info':effect})
			effect_item.set_meta('filter_button', %Filter_EffectsAndModifiers)
			effect_item.visible = %Filter_EffectsAndModifiers.button_pressed

		# Text Modifiers
		for mod in i._get_text_modifiers():
			var mod_item : TreeItem = %Tree.create_item(module_item)
			mod_item.set_icon(0, get_theme_icon("RichTextEffect", "EditorIcons"))
			mod_item.set_text(0, mod.method.capitalize())
			mod_item.set_icon_modulate(0, get_theme_color("property_color_z", "Editor"))
			mod_item.set_metadata(0, {'type':'Modifier', 'info':mod})
			mod_item.set_meta('filter_button', %Filter_EffectsAndModifiers)
			mod_item.visible = %Filter_EffectsAndModifiers.button_pressed

		# Settings
		for settings in i._get_settings_pages():
			var settings_item : TreeItem = %Tree.create_item(module_item)
			settings_item.set_icon(0, get_theme_icon("PluginScript", "EditorIcons"))
			settings_item.set_text(0, module_item.get_text(0) + " Settings")
			settings_item.set_icon_modulate(0, get_theme_color("readonly_color", "Editor"))
			settings_item.set_metadata(0, {'type':'Settings', 'info':settings})
			settings_item.set_meta('filter_button', %Filter_Settings)
			settings_item.visible = %Filter_Settings.button_pressed

		# Editors
		for editor in i._get_editors():
			var editor_item : TreeItem = %Tree.create_item(module_item)
			editor_item.set_icon(0, get_theme_icon("ConfirmationDialog", "EditorIcons"))
			editor_item.set_text(0, editor.get_file().trim_suffix('.tscn').capitalize())
			editor_item.set_icon_modulate(0, get_theme_color("readonly_color", "Editor"))
			editor_item.set_metadata(0, {'type':'Editor', 'info':editor})
			editor_item.set_meta('filter_button', %Filter_Editors)
			editor_item.visible = %Filter_Editors.button_pressed

		module_item.collapsed = %Collapse.button_pressed

	_on_search_text_changed(%Search.text)
	if %Tree.get_root().get_child_count(): %Tree.set_selected(%Tree.get_root().get_child(0), 0)


func _on_tree_button_clicked(item:TreeItem, column:int, id:int, mouse_button_index:int) -> void:
	match item.get_metadata(0)['type']:
		'Module':
			item.collapsed = false
			%Tree.set_selected(item.get_child(id), 0)
		'Event':
			# Visibility item clicked
			if id == 0:
				var meta :Dictionary= item.get_metadata(0)
				if meta['hidden']:
					item.set_button(0, 0, get_theme_icon("GuiVisibilityVisible", "EditorIcons"))
					item.get_parent().set_button_color(0, item.get_index(), item.get_icon_modulate(0))
					if item == %Tree.get_selected():
						%VisibilityToggle.button_pressed = true
				else:
					item.set_button(0, 0, get_theme_icon("GuiVisibilityHidden", "EditorIcons"))
					var color : Color = item.get_icon_modulate(0)
					color.a = 0.5
					item.get_parent().set_button_color(0, item.get_index(), color)
					if item == %Tree.get_selected():
						%VisibilityToggle.button_pressed = false
				meta['hidden'] = !meta['hidden']
				item.set_metadata(0, meta)
				change_event_visibility(meta['event'], !meta['hidden'])


func _on_tree_item_selected() -> void:
	var selected_item :TreeItem = %Tree.get_selected()

	var metadata :Variant = selected_item.get_metadata(0)

	%Title.text = selected_item.get_text(0)
	%EventDefaultsPanel.hide()
	%Icon.texture = null
	%ExternalLink.hide()
	%VisibilityToggle.hide()

	if metadata is Dictionary:
		match metadata.type:
			'Event':
				%GeneralInfo.text = "Events can be used in timelines and do all kinds of things. They often interact with subsystems and dialogic nodes."

				load_event_settings(metadata.event)
				if %EventDefaults.get_child_count():
					%EventDefaultsPanel.show()

				if metadata.event.help_page_path:
					%ExternalLink.show()
					%ExternalLink.set_meta('url', metadata.event.help_page_path)
				%Icon.texture = metadata.event._get_icon()
				if !metadata.event.disable_editor_button:
					%VisibilityToggle.show()
					%VisibilityToggle.button_pressed = !metadata.event.event_name in DialogicUtil.get_editor_setting('hidden_event_buttons', [])
					if %VisibilityToggle.button_pressed:
						%VisibilityToggle.icon = get_theme_icon("GuiVisibilityVisible", "EditorIcons")
					else:
						%VisibilityToggle.icon = get_theme_icon("GuiVisibilityHidden", "EditorIcons")
			# -------------------------------------------------
			'Subsystem':
				%GeneralInfo.text = "Subsystems hold specialized functionality. They mostly manage communication between events and dialogic nodes. Often they provide handy methods that can be accessed by the user like this: Dialogic.Subsystem.a_method()."
			# -------------------------------------------------
			'Effect':
				%GeneralInfo.text = "Text effects can be used in text events. They will be executed once reached and can take a single argument."
			# -------------------------------------------------
			'Modifier':
				%GeneralInfo.text = "Modifiers can modify text from text events before it is shown."
			# -------------------------------------------------
			'Style':
				%GeneralInfo.text = "Style presets can be activated and modified in the Styles editor. They provide the design of the dialog interface in your game."
			# -------------------------------------------------
			'Editor':
				%GeneralInfo.text = "Editors provide a user interface for editing dialogic data."
			# -------------------------------------------------
			'Settings':
				%GeneralInfo.text = "Settings pages provide settings that are usually used by subsystems, events and dialogic nodes."
			# -------------------------------------------------
			'_':
				%GeneralInfo.text = ""


func _on_external_link_pressed():
	if %ExternalLink.has_meta('url'):
		OS.shell_open(%ExternalLink.get_meta('url'))


func change_event_visibility(event:DialogicEvent, visibility:bool) -> void:
	if event:
		var list :Array= DialogicUtil.get_editor_setting('hidden_event_buttons', [])
		if visibility:
			list.erase(event.event_name)
		else:
			list.append(event.event_name)
		DialogicUtil.set_editor_setting('hidden_event_buttons', list)
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
		var color : Color = %Tree.get_selected().get_icon_modulate(0)
		color.a = 0.5
		%Tree.get_selected().get_parent().set_button_color(0, %Tree.get_selected().get_index(), color)



func force_event_button_list_update() -> void:
	find_parent('EditorsManager').editors['Timeline'].node.get_node('%VisualEditor').load_event_buttons()

################################################################################
##						EVENT DEFAULT SETTINGS
################################################################################
func load_event_settings(event:DialogicEvent) -> void:
	for child in %EventDefaults.get_children():
		child.queue_free()

	var event_default_overrides :Dictionary = ProjectSettings.get_setting('dialogic/event_default_overrides', {})

	var params := event.get_shortcode_parameters()
	for prop in params:
		# Label
		var label := Label.new()
		label.text = prop.capitalize()
		%EventDefaults.add_child(label)

		# Editing field
		var editor_node :Node = null
		var current_value :Variant = params[prop].default
		if event_default_overrides.get(event.event_name, {}).has(params[prop].property):
			current_value = event_default_overrides.get(event.event_name, {}).get(params[prop].property)

		match typeof(event.get(params[prop].property)):
			TYPE_STRING:
				editor_node = LineEdit.new()
				editor_node.custom_minimum_size.x = 150
				editor_node.text = str(current_value)
				editor_node.text_changed.connect(_on_event_default_string_submitted.bind(params[prop].property))
			TYPE_INT, TYPE_FLOAT:
				if params[prop].has('suggestions'):
					editor_node = OptionButton.new()
					for i in params[prop].suggestions.call():
						editor_node.add_item(i, int(params[prop].suggestions.call()[i].value))
					editor_node.select(int(current_value))
					editor_node.item_selected.connect(_on_event_default_option_selected.bind(editor_node, params[prop].property))
				else:
					editor_node = SpinBox.new()

					editor_node.allow_greater = true
					editor_node.allow_lesser = true
					if typeof(event.get(params[prop].property)) == TYPE_INT:
						editor_node.step = 1
					else:
						editor_node.step = 0.001

					editor_node.value = float(current_value)
					editor_node.value_changed.connect(_on_event_default_number_changed.bind(params[prop].property))

			TYPE_VECTOR2:
				editor_node = load("res://addons/dialogic/Editor/Events/Fields/Vector2.tscn").instantiate()
				editor_node.set_value(current_value)
				editor_node.property_name = params[prop].property
				editor_node.value_changed.connect(_on_event_default_value_changed)

			TYPE_BOOL:
				editor_node = CheckBox.new()
				editor_node.button_pressed = bool(current_value)
				editor_node.toggled.connect(_on_event_default_bool_toggled.bind(params[prop].property))

			TYPE_ARRAY:
				editor_node = load("res://addons/dialogic/Editor/Events/Fields/Array.tscn").instantiate()
				editor_node.set_value(current_value)
				editor_node.property_name = params[prop].property
				editor_node.value_changed.connect(_on_event_default_value_changed)

		%EventDefaults.add_child(editor_node)


func set_event_default_override(prop:String, value:Variant) -> void:
	var event_default_overrides :Dictionary = ProjectSettings.get_setting('dialogic/event_default_overrides', {})
	var event :DialogicEvent = %Tree.get_selected().get_metadata(0).event

	if not event_default_overrides.has(event.event_name):
		event_default_overrides[event.event_name] = {}

	event_default_overrides[event.event_name][prop] = value

	ProjectSettings.set_setting('dialogic/event_default_overrides', event_default_overrides)




func _on_event_default_string_submitted(text:String, prop:String) -> void:
	set_event_default_override(prop, text)

func _on_event_default_option_selected(index:int, option_button:OptionButton, prop:String) -> void:
	set_event_default_override(prop, option_button.get_item_id(index))

func _on_event_default_number_changed(value:float, prop:String) -> void:
	set_event_default_override(prop, value)

func _on_event_default_value_changed(prop:String, value:Vector2) -> void:
	set_event_default_override(prop, value)

func _on_event_default_bool_toggled(value:bool, prop:String) -> void:
	set_event_default_override(prop, value)

