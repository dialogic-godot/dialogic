@tool
extends DialogicEditor

## Editor that contains all settings 

var button_group := ButtonGroup.new()
var registered_sections :Array[DialogicSettingsPage] = []


func _get_title() -> String:
	return "Settings"


func _get_icon() -> Texture:
	return get_theme_icon("PluginScript", "EditorIcons")


func _register():
	editors_manager.register_simple_editor(self)
	self.alternative_text = "Customize dialogic and it's behaviour" 


func _ready():
	if get_parent() is SubViewport:
		return
	
	register_settings_section("res://addons/dialogic/Editor/Settings/settings_general.tscn")
	register_settings_section("res://addons/dialogic/Editor/Settings/settings_translation.tscn")
	register_settings_section("res://addons/dialogic/Editor/Settings/settings_modules.tscn")
	
	for indexer in DialogicUtil.get_indexers():
		for settings_page in indexer._get_settings_pages():
			register_settings_section(settings_page)
	
	add_registered_sections()
	%SettingsTabs.get_child(0).button_pressed = true
	%SettingsContent.get_child(0).show()


func register_settings_section(path:String) -> void:
	var section :Control = load(path).instantiate()
	
	registered_sections.append(section)


func add_registered_sections() -> void:
	for i in %SettingsTabs.get_children():
		i.queue_free()
	for i in %FeatureTabs.get_children():
		i.queue_free()
	
	for i in %SettingsContent.get_children():
		i.queue_free()
	
	
	registered_sections.sort_custom(section_sort)
	for section in registered_sections:
		
		section.name = section._get_title()
		
		var vbox := VBoxContainer.new()
		vbox.set_meta('section', section)
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.name = section.name
		var hbox := HBoxContainer.new()
		
		var title := Label.new()
		title.text = section.name
		title.theme_type_variation = 'DialogicSectionBig'
		hbox.add_child(title)
		vbox.add_child(hbox)
		
		
		if !section.short_info.is_empty():
			var tooltip_hint :Control = load("res://addons/dialogic/Editor/Common/hint_tooltip_icon.tscn").instantiate()
			tooltip_hint.hint_text = section.short_info
			hbox.add_child(tooltip_hint)
		
		
		var scroll := ScrollContainer.new()
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var inner_vbox := VBoxContainer.new()
		inner_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inner_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.add_child(inner_vbox)
		var panel := PanelContainer.new()
		panel.theme_type_variation = "DialogicPanelA"
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if section.size_flags_vertical == Control.SIZE_EXPAND_FILL:
			panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		inner_vbox.add_child(panel)
		
		
		var info_section :Control = section._get_info_section() 
		if info_section != null:
			inner_vbox.add_child(Control.new())
			inner_vbox.get_child(-1).custom_minimum_size.y = 50
			
			inner_vbox.add_child(title.duplicate())
			inner_vbox.get_child(-1).text = "Information"
			var info_panel := panel.duplicate()
			info_panel.theme_type_variation = "DialogicPanelDarkA"
			
			inner_vbox.add_child(info_panel)
			info_section.get_parent().remove_child(info_section)
			info_panel.add_child(info_section)
		
		panel.add_child(section)
		vbox.add_child(scroll)
		
		
		var button := Button.new()
		button.text = " "+section.name
		button.tooltip_text = section.name
		button.toggle_mode = true
		button.button_group = button_group
		button.expand_icon = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.flat = true
		button.add_theme_color_override('font_pressed_color', get_theme_color("property_color_z", "Editor"))
		button.add_theme_color_override('font_hover_color', get_theme_color('warning_color', 'Editor'))
		button.add_theme_color_override('font_focus_color', get_theme_color('warning_color', 'Editor'))
		button.add_theme_stylebox_override('focus', StyleBoxEmpty.new())
		button.pressed.connect(open_tab.bind(vbox))
		if section._is_feature_tab():
			%FeatureTabs.add_child(button)
		else:
			%SettingsTabs.add_child(button)
		
		vbox.hide()
#		if section.has_method('_get_icon'):
#			icon.texture = section._get_icon()
		%SettingsContent.add_child(vbox)


func open_tab(tab_to_show:Control) -> void:
	for tab in %SettingsContent.get_children():
		tab.hide()
	
	tab_to_show.show()


func section_sort(item1:DialogicSettingsPage, item2:DialogicSettingsPage) -> bool:
	if !item1._is_feature_tab() and item2._is_feature_tab():
		return true
	if item1._get_priority() > item2._get_priority():
		return true
	return false



func _open(extra_information:Variant = null) -> void:
	refresh()
	if typeof(extra_information) == TYPE_STRING:
		if %SettingsContent.has_node(extra_information):
			open_tab(%SettingsContent.get_node(extra_information))


func _close():
	for child in %SettingsContent.get_children():
		if child.get_meta('section').has_method('_about_to_close'):
			child.get_meta('section')._about_to_close()


func refresh():
	for child in %SettingsContent.get_children():
		if child.get_meta('section').has_method('_refresh'):
			child.get_meta('section')._refresh()

