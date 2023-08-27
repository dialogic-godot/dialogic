@tool
extends Control

## Script that handles the editor sidebar. 

signal file_activated(file_path)

signal content_item_activated(item_name)

@onready var editors_manager = get_parent().get_parent()


func _ready():
	if owner.get_parent() is SubViewport:
		return
	
	## CONNECTIONS
	%ResourcesList.item_selected.connect(_on_resources_list_item_selected)
	%ResourcesList.item_clicked.connect(_on_resources_list_item_clicked)
	editors_manager.resource_opened.connect(_on_editors_resource_opened)
	editors_manager.editor_changed.connect(_on_editors_editor_changed)
	
	%ContentList.item_selected.connect(func (idx:int): content_item_activated.emit(%ContentList.get_item_text(idx)))
	
	var editor_scale := DialogicUtil.get_editor_scale()
	## ICONS
	%Logo.texture = load("res://addons/dialogic/Editor/Images/dialogic-logo.svg")
	%Logo.custom_minimum_size.y = 30*editor_scale
	%Search.right_icon = get_theme_icon("Search", "EditorIcons")
	
	%CurrentResource.add_theme_stylebox_override('normal', get_theme_stylebox('normal', 'LineEdit'))
	
	%ContentList.add_theme_color_override("font_hovered_color", get_theme_color("warning_color", "Editor"))
	%ContentList.add_theme_color_override("font_selected_color", get_theme_color("property_color_z", "Editor"))
	
	## MARGINS
	$VBox/Margin.set("theme_override_constants/margin_left", 4 * editor_scale)
	$VBox/Margin.set("theme_override_constants/margin_bottom", 4 * editor_scale)
	
	## VERSION LABEL
	var plugin_cfg := ConfigFile.new()
	plugin_cfg.load("res://addons/dialogic/plugin.cfg")
	%CurrentVersion.text = plugin_cfg.get_value('plugin', 'version', 'unknown version')
	
	


################################################################################
## 						RESOURCE LIST 
################################################################################

func _on_editors_resource_opened(resource:Resource) -> void:
	update_resource_list()


func _on_editors_editor_changed(previous:DialogicEditor, current:DialogicEditor) -> void:
	%ContentListSection.visible = current.current_resource is DialogicTimeline
	update_resource_list()


func update_resource_list(resources_list:PackedStringArray = []) -> void:
	var filter :String = %Search.text
	var current_file := ""
	if editors_manager.current_editor and editors_manager.current_editor.current_resource:
		current_file = editors_manager.current_editor.current_resource.resource_path
	
	var character_directory: Dictionary = editors_manager.resource_helper.character_directory
	var timeline_directory: Dictionary = editors_manager.resource_helper.timeline_directory
	if resources_list.is_empty():
		resources_list = DialogicUtil.get_editor_setting('last_resources', [])
		if !current_file in resources_list:
			resources_list.append(current_file)
	
	%CurrentResource.text = "No Resource"
	%CurrentResource.add_theme_color_override("font_color", get_theme_color("disabled_font_color", "Editor"))
	
	%ResourcesList.clear()
	var idx := 0
	for character in character_directory.values():
		if character['full_path'] in resources_list:
			if filter.is_empty() or filter.to_lower() in character['unique_short_path'].to_lower():
				%ResourcesList.add_item(
						character['unique_short_path'], 
						load("res://addons/dialogic/Editor/Images/Resources/character.svg"))
				%ResourcesList.set_item_metadata(idx, character['full_path'])
				%ResourcesList.set_item_tooltip(idx, character['full_path'])
				if character['full_path'] == current_file:
					%ResourcesList.select(idx)
					%ResourcesList.set_item_custom_fg_color(idx, get_theme_color("accent_color", "Editor"))
					%CurrentResource.text = character['unique_short_path']+'.dch'
				idx += 1
	for timeline_name in timeline_directory:
		if timeline_directory[timeline_name] in resources_list:
			if filter.is_empty() or filter.to_lower() in timeline_name.to_lower():
				%ResourcesList.add_item(timeline_name, get_theme_icon("TripleBar", "EditorIcons"))
				%ResourcesList.set_item_metadata(idx, timeline_directory[timeline_name])
				if timeline_directory[timeline_name] == current_file:
					%ResourcesList.select(idx)
					%ResourcesList.set_item_custom_fg_color(idx, get_theme_color("accent_color", "Editor"))
					%CurrentResource.text = timeline_name+'.dtl'
				idx += 1
	if %CurrentResource.text != "No Resource":
		%CurrentResource.add_theme_color_override("font_color", get_theme_color("font_color", "Editor"))
	%ResourcesList.sort_items_by_text()
	DialogicUtil.set_editor_setting('last_resources', resources_list)


func _on_resources_list_item_selected(index:int) -> void:
	if %ResourcesList.get_item_metadata(index) == null:
		return
	editors_manager.edit_resource(load(%ResourcesList.get_item_metadata(index)))


func _on_resources_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	# If clicked with the middle mouse button, remove the item from the list
	if mouse_button_index == 3:
		var new_list := []
		for entry in DialogicUtil.get_editor_setting('last_resources', []):
			if entry != %ResourcesList.get_item_metadata(index):
				new_list.append(entry)
		DialogicUtil.set_editor_setting('last_resources', new_list)
		%ResourcesList.remove_item(index)


func _on_search_text_changed(new_text:String) -> void:
	update_resource_list()


func set_unsaved_indicator(saved:bool = true) -> void:
	if saved and %CurrentResource.text.ends_with('(*)'):
		%CurrentResource.text = %CurrentResource.text.trim_suffix('(*)')
	if not saved and not %CurrentResource.text.ends_with('(*)'):
		%CurrentResource.text = %CurrentResource.text+"(*)"


func _on_logo_gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		editors_manager.open_editor(editors_manager.editors['HomePage'].node)


func update_content_list(list:PackedStringArray) -> void:
	var prev_selected := ""
	if %ContentList.is_anything_selected():
		prev_selected = %ContentList.get_item_text(%ContentList.get_selected_items()[0])
	%ContentList.clear()
	%ContentList.add_item('~ Top')
	for i in list:
		if i.is_empty(): continue
		%ContentList.add_item(i)
		if i == prev_selected:
			%ContentList.select(%ContentList.item_count-1)
	if list.is_empty():
		return
	
	for i in editors_manager.resource_helper.timeline_directory:
		if editors_manager.resource_helper.timeline_directory[i] == editors_manager.get_current_editor().current_resource.resource_path:
			editors_manager.resource_helper.label_directory[i] = list
	editors_manager.resource_helper.label_directory[''] = list
	DialogicUtil.set_editor_setting('label_ref', editors_manager.resource_helper.label_directory)
