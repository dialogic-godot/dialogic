@tool
extends VSplitContainer

signal file_activated

func _ready():
	load_recent_files()

func load_recent_files(latest_file:String = ""):
	var character_directory :Dictionary = find_parent('EditorView').character_directory
	var timeline_directory :Dictionary = find_parent('EditorView').timeline_directory
	var latest_resources :Array = DialogicUtil.get_project_setting('dialogic/editor/last_resources', [])
	%ResourcesList.clear()
	var idx := 0
	for character in character_directory.values():
		if character['full_path'] in latest_resources:
			%ResourcesList.add_item(character['unique_short_path'], load("res://addons/dialogic/Editor/Images/Resources/character.svg"))
			%ResourcesList.set_item_metadata(idx, character['full_path'])
			%ResourcesList.set_item_tooltip(idx, character['full_path'])
			if character['full_path'] == latest_file:
				%ResourcesList.select(idx)
				%ResourcesList.set_item_custom_fg_color(idx, get_theme_color("accent_color", "Editor"))
			idx += 1
	for timeline_name in timeline_directory:
		if timeline_directory[timeline_name] in latest_resources:
			%ResourcesList.add_item(timeline_name, get_theme_icon("TripleBar", "EditorIcons"))
			%ResourcesList.set_item_metadata(idx, timeline_directory[timeline_name])
			if timeline_directory[timeline_name] == latest_file:
				%ResourcesList.select(idx)
				%ResourcesList.set_item_custom_fg_color(idx, get_theme_color("accent_color", "Editor"))
			idx += 1
	%ResourcesList.sort_items_by_text()

func _on_resources_list_item_activated(index):
	DialogicUtil.get_dialogic_plugin().editor_interface.inspect_object(load(%ResourcesList.get_item_metadata(index)))
