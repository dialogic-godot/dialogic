@tool
extends Control

## Script that handles the editor sidebar. 

signal file_activated(file_path)

@onready var editors_manager = get_parent().get_parent()


func _ready():
	%ResourcesList.item_selected.connect(_on_resources_list_item_selected)
	editors_manager.ready.connect(load_recent_files)
	
	%Search.right_icon = get_theme_icon("Search", "EditorIcons")

################################################################################
## 					EDITOR BUTTONS/LABELS 
################################################################################

func add_icon_button(icon: Texture, tooltip: String) -> Button:
	var button := Button.new()
	button.icon = icon
	button.tooltip_text = tooltip
	%IconButtons.add_child(button)
	return button


func add_custom_button(label:String, icon:Texture) -> Button:
	var button := Button.new()
	button.text = label
	button.icon = icon
	%CustomButtons.add_child(button)
	return button


func hide_all_custom_buttons() -> void:
	for button in %CustomButtons.get_children():
		button.hide()


func set_current_resource_text(text:String) -> void:
	%CurrentResource.text = text
	%CurrentResource.visible = not text.is_empty()

func set_unsaved_indicator(saved:bool = true) -> void:
	if saved and %CurrentResource.text.ends_with('(*)'):
		%CurrentResource.text = %CurrentResource.text.trim_suffix('(*)')
	if not saved and not %CurrentResource.text.ends_with('(*)'):
		%CurrentResource.text = %CurrentResource.text+"(*)"

################################################################################
## 						RESOURCE LIST 
################################################################################

func load_recent_files(latest_file:String = "", filter:String = "") -> void:
	var character_directory: Dictionary = editors_manager.resource_helper.character_directory
	var timeline_directory: Dictionary = editors_manager.resource_helper.timeline_directory
	var latest_resources: Array = DialogicUtil.get_project_setting('dialogic/editor/last_resources', [])
	%ResourcesList.clear()
	var idx := 0
	for character in character_directory.values():
		if character['full_path'] in latest_resources:
			if filter.is_empty() or filter.to_lower() in character['unique_short_path'].to_lower():
				%ResourcesList.add_item(
						character['unique_short_path'], 
						load("res://addons/dialogic/Editor/Images/Resources/character.svg"))
				%ResourcesList.set_item_metadata(idx, character['full_path'])
				%ResourcesList.set_item_tooltip(idx, character['full_path'])
				if character['full_path'] == latest_file:
					%ResourcesList.select(idx)
					%ResourcesList.set_item_custom_fg_color(idx, get_theme_color("accent_color", "Editor"))
				idx += 1
	for timeline_name in timeline_directory:
		if timeline_directory[timeline_name] in latest_resources:
			if filter.is_empty() or filter.to_lower() in timeline_name.to_lower():
				%ResourcesList.add_item(timeline_name, get_theme_icon("TripleBar", "EditorIcons"))
				%ResourcesList.set_item_metadata(idx, timeline_directory[timeline_name])
				if timeline_directory[timeline_name] == latest_file:
					%ResourcesList.select(idx)
					%ResourcesList.set_item_custom_fg_color(idx, get_theme_color("accent_color", "Editor"))
				idx += 1
	%ResourcesList.sort_items_by_text()


func _on_resources_list_item_selected(index:int) -> void:
	editors_manager.edit_resource(load(%ResourcesList.get_item_metadata(index)))


func _on_search_text_changed(new_text:String) -> void:
	load_recent_files("", new_text)
