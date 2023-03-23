@tool
extends Control

## Script that handles the editor sidebar. 

signal file_activated(file_path)

@onready var editors_manager = get_parent().get_parent()


func _ready():
	%ResourcesList.item_selected.connect(_on_resources_list_item_selected)
	%ResourcesList.item_clicked.connect(_on_resources_list_item_clicked)
	editors_manager.resource_opened.connect(_on_editors_resource_opened)
	editors_manager.editor_changed.connect(_on_editors_editor_changed)
	%Search.right_icon = get_theme_icon("Search", "EditorIcons")
	var editor_scale = DialogicUtil.get_editor_scale()
	$VBoxContainer/MarginContainer.set("theme_override_constants/margin_left", 4 * editor_scale)
	$VBoxContainer/MarginContainer.set("theme_override_constants/margin_bottom", 4 * editor_scale)
	var plugin_cfg := ConfigFile.new()
	plugin_cfg.load("res://addons/dialogic/plugin.cfg")
	%CurrentVersion.text = plugin_cfg.get_value('plugin', 'version', 'unknown version')

################################################################################
## 					EDITOR BUTTONS/LABELS 
################################################################################

func add_icon_button(icon: Texture, tooltip: String) -> Button:
	var button := Button.new()
	button.icon = icon
	button.tooltip_text = tooltip
	%IconButtons.add_child(button)
	return button


################################################################################
## 						RESOURCE LIST 
################################################################################

func _on_editors_resource_opened(resource:Resource) -> void:
	update_resource_list()


func _on_editors_editor_changed(previous:DialogicEditor, current:DialogicEditor) -> void:
	update_resource_list()


func update_resource_list(resources_list:PackedStringArray = []) -> void:
	var filter :String = %Search.text
	var current_file := ""
	if editors_manager.current_editor and editors_manager.current_editor.current_resource:
		current_file = editors_manager.current_editor.current_resource.resource_path
	
	var character_directory: Dictionary = editors_manager.resource_helper.character_directory
	var timeline_directory: Dictionary = editors_manager.resource_helper.timeline_directory
	if resources_list.is_empty():
		resources_list = ProjectSettings.get_setting('dialogic/editor/last_resources', [])
		if !current_file in resources_list:
			resources_list.append(current_file)
	
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
				idx += 1
	for timeline_name in timeline_directory:
		if timeline_directory[timeline_name] in resources_list:
			if filter.is_empty() or filter.to_lower() in timeline_name.to_lower():
				%ResourcesList.add_item(timeline_name, get_theme_icon("TripleBar", "EditorIcons"))
				%ResourcesList.set_item_metadata(idx, timeline_directory[timeline_name])
				if timeline_directory[timeline_name] == current_file:
					%ResourcesList.select(idx)
					%ResourcesList.set_item_custom_fg_color(idx, get_theme_color("accent_color", "Editor"))
				idx += 1
	%ResourcesList.sort_items_by_text()
	ProjectSettings.set_setting('dialogic/editor/last_resources', resources_list)


func _on_resources_list_item_selected(index:int) -> void:
	if %ResourcesList.get_item_metadata(index) == null:
		return
	editors_manager.edit_resource(load(%ResourcesList.get_item_metadata(index)))
	

func _on_resources_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int):
	# If clicked with the middle mouse button, remove the item from the list
	if mouse_button_index == 3:
		var new_list = []
		for entry in ProjectSettings.get_setting('dialogic/editor/last_resources', []):
			if entry != %ResourcesList.get_item_metadata(index):
				new_list.append(entry)
		ProjectSettings.set_setting('dialogic/editor/last_resources', new_list)
		%ResourcesList.remove_item(index)

func _on_search_text_changed(new_text:String) -> void:
	update_resource_list()
