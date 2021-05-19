tool
extends Tree

onready var editor_reference = get_node('../../../')
onready var timeline_editor = get_node('../../TimelineEditor')
onready var character_editor = get_node('../../CharacterEditor')
onready var definition_editor = get_node('../../DefinitionEditor')
onready var settings_editor = get_node('../../SettingsEditor')
onready var theme_editor = get_node('../../ThemeEditor')
onready var empty_editor = get_node('../../Empty')
onready var filter_tree_edit = get_node('../FilterMasterTreeEdit')

onready var tree = self

var timeline_icon
var character_icon
var theme_icon
var definition_icon
var glossary_icon

var timelines_tree
var characters_tree
var definitions_tree
var themes_tree
var settings_tree

var item_path_before_edit = ""

var rmb_popup_menus = {}

var filter_tree_term = ''

signal editor_selected(selected)

func _ready():
	allow_rmb_select = true
	var root = tree.create_item()
	tree.set_hide_root(true)
	
	var modifier = ''
	var _scale = get_constant("inspector_margin", "Editor")
	_scale = _scale * 0.125
	rect_min_size.x = 150
	if _scale == 1.25:
		modifier = '-1.25'
		rect_min_size.x = 180
	if _scale == 1.5:
		modifier = '-1.25'
		rect_min_size.x = 250
	if _scale == 1.75:
		modifier = '-1.25'
		rect_min_size.x = 250
	if _scale == 2:
		modifier = '-2'
		rect_min_size.x = 360
	rect_size.x = 0
	timeline_icon = load("res://addons/dialogic/Images/Resources/timeline" + modifier + ".svg")
	character_icon = load("res://addons/dialogic/Images/Resources/character" + modifier + ".svg")
	theme_icon = load("res://addons/dialogic/Images/Resources/theme" + modifier + ".svg")
	definition_icon = load("res://addons/dialogic/Images/Resources/definition" + modifier + ".svg")
	glossary_icon = get_icon("ListSelect", "EditorIcons")
	
	# Creating the parents
	timelines_tree = tree.create_item(root)
	timelines_tree.set_text(0, "Timelines")
	timelines_tree.set_icon(0, get_icon("Folder", "EditorIcons"))
	timelines_tree.set_metadata(0, {'editor': 'Timeline Root'})
	
	characters_tree = tree.create_item(root)
	characters_tree.set_text(0, "Characters")
	characters_tree.set_icon(0, get_icon("Folder", "EditorIcons"))
	characters_tree.set_metadata(0, {'editor': 'Character Root'})

	definitions_tree = tree.create_item(root)
	definitions_tree.set_text(0, "Definitions")
	definitions_tree.set_icon(0, get_icon("Folder", "EditorIcons"))
	definitions_tree.set_metadata(0, {'editor': 'Definition Root'})
	
	themes_tree = tree.create_item(root)
	themes_tree.set_text(0, "Themes")
	themes_tree.set_icon(0, get_icon("Folder", "EditorIcons"))
	themes_tree.set_metadata(0, {'editor': 'Theme Root'})
	
	settings_tree = tree.create_item(root)
	settings_tree.set_text(0, "Settings")
	settings_tree.set_icon(0, get_icon("GDScript", "EditorIcons"))
	settings_tree.set_metadata(0, {'editor': 'Settings'})
	
	create_rmb_context_menus()
	
	connect('item_selected', self, '_on_item_selected')
	connect('item_rmb_selected', self, '_on_item_rmb_selected')
	connect('gui_input', self, '_on_gui_input')
	connect('item_edited', self, '_on_item_edited')
	$RenamerReset.connect("timeout", self, '_on_renamer_reset_timeout')
	
	filter_tree_edit.connect("text_changed", self, '_on_filter_tree_edit_changed')
	
	#var subchild1 = tree.create_item(timelines_tree)
	#subchild1.set_text(0, "Subchild1")
	
	# Adding timelines
	build_timelines()
	
	# Adding characters
	build_characters()
	
	# Adding Definitions
	build_definitions()
	
	# Adding Themes
	build_themes()
	
	# Default empty screen.
	hide_all_editors() 
	
	# AutoSave timer
	$AutoSave.connect("timeout", self, '_on_autosave_timeout')
	$AutoSave.start(0.5)


func _clear_tree_children(parent: TreeItem):
	while parent.get_children() != null:
		parent.get_children().free()


func build_timelines(selected_item: String=''):
	_clear_tree_children(timelines_tree)
	
	DialogicUtil.update_resource_folder_structure()
	var structure = DialogicUtil.get_timelines_folder_structure()
	build_timelines_folder(timelines_tree, structure, selected_item)

func build_timelines_folder(parent_folder_item, folder_data, selected_item):
	
	for folder in folder_data["folders"].keys():
		build_timelines_folder(_add_folder_item(parent_folder_item, folder, 'Timeline Root'), folder_data["folders"][folder], selected_item)
	
	for file in folder_data["files"]:
		var file_metadata = DialogicUtil.get_timeline_dict()[file]
		if (filter_tree_term == '') or (filter_tree_term.to_lower() in file_metadata['name'].to_lower()):
			_add_timeline(parent_folder_item, file_metadata, not selected_item.empty() and file == selected_item)
	
	# force redraw control
	update()

func _add_folder_item(parent_item, folder_name, editor):
	var folder_item = tree.create_item(parent_item)
	folder_item.set_text(0, folder_name)
	folder_item.set_icon(0, get_icon("Folder", "EditorIcons"))
	folder_item.set_metadata(0, {'editor': editor, 'editable': true})
	return folder_item
#
#func trash():
#	for t in DialogicUtil.get_sorted_timeline_list():
#		if (filter_tree_term != ''):
#			if (filter_tree_term.to_lower() in t['file'].to_lower() or filter_tree_term.to_lower() in t['name'].to_lower()):
#				_add_timeline(t, not selected_item.empty() and t['file'] == selected_item)
#		else:
#			_add_timeline(t, not selected_item.empty() and t['file'] == selected_item)
#	# force redraw control
#	update()

func _add_timeline(parent_item, timeline_data, select = false):
	var item = tree.create_item(parent_item)
	item.set_icon(0, timeline_icon)
	if timeline_data.has('name'):
		item.set_text(0, timeline_data['name'])
	else:
		item.set_text(0, timeline_data['file'])
	timeline_data['editor'] = 'Timeline'
	timeline_data['editable'] = true
	item.set_metadata(0, timeline_data)
	if not get_constant("dark_theme", "Editor"):
		item.set_icon_modulate(0, get_color("property_color", "Editor"))
	#item.set_editable(0, true)
	if select: # Auto selecting
		item.select(0)


func build_themes(selected_item: String=''):
	_clear_tree_children(themes_tree)
	for t in DialogicUtil.get_sorted_theme_list():
		if (filter_tree_term != ''):
			if (filter_tree_term.to_lower() in t['file'].to_lower() or filter_tree_term.to_lower() in t['name'].to_lower()):
				_add_theme(t, not selected_item.empty() and t['file'] == selected_item)
		else:
			_add_theme(t, not selected_item.empty() and t['file'] == selected_item)
	# force redraw tree
	update()


func _add_theme(theme_item, select = false):
	var item = tree.create_item(themes_tree)
	item.set_icon(0, theme_icon)
	item.set_text(0, theme_item['name'])
	theme_item['editor'] = 'Theme'
	theme_item['editable'] = true
	item.set_metadata(0, theme_item)
	if not get_constant("dark_theme", "Editor"):
		item.set_icon_modulate(0, get_color("property_color", "Editor"))
	if select: # Auto selecting
		item.select(0)


func build_characters(selected_item: String=''):
	_clear_tree_children(characters_tree)
	for t in DialogicUtil.get_sorted_character_list():
		if (filter_tree_term != ''):
			if (filter_tree_term.to_lower() in t['file'].to_lower() or filter_tree_term.to_lower() in t['name'].to_lower()):
				_add_character(t, not selected_item.empty() and t['file'] == selected_item)
		else:		
			_add_character(t, not selected_item.empty() and t['file'] == selected_item)
	# force redraw tree
	update()


func _add_character(character, select = false):
	var item = tree.create_item(characters_tree)
	item.set_icon(0, character_icon)
	if character.has('name'):
		item.set_text(0, character['name'])
	else:
		item.set_text(0, character['file'])
	character['editor'] = 'Character'
	character['editable'] = true
	item.set_metadata(0, character)
	#item.set_editable(0, true)
	if character.has('color'):
		item.set_icon_modulate(0, character['color'])
	# Auto selecting
	if select: 
		item.select(0)


func build_definitions(selected_item: String=''):
	_clear_tree_children(definitions_tree)
	for t in DialogicUtil.get_sorted_default_definitions_list():
		if (filter_tree_term != ''):
			if (filter_tree_term.to_lower() in t['name'].to_lower()):
				_add_definition(t, not selected_item.empty() and t['id'] == selected_item)
		else:		
			_add_definition(t, not selected_item.empty() and t['id'] == selected_item)
	# force redraw tree
	update()


func _add_definition(definition, select = false):
	var item = tree.create_item(definitions_tree)
	item.set_text(0, definition['name'])
	item.set_icon(0, definition_icon)
	if definition['type'] == 1:
		item.set_icon(0, glossary_icon)
	definition['editor'] = 'Definition'
	definition['editable'] = true
	item.set_metadata(0, definition)
	if not get_constant("dark_theme", "Editor"):
		item.set_icon_modulate(0, get_color("property_color", "Editor"))
	if select: # Auto selecting
		item.select(0)


func _on_item_selected():
	# TODO: Ideally I would perform a "save" here before opening the next
	#       resource. Unfortunately there has been so many bugs doing that 
	#       that I'll revisit it in the future. 
	#       save_current_resource()
	var item = get_selected()
	var metadata = item.get_metadata(0)
	if metadata['editor'] == 'Timeline':
		timeline_editor.load_timeline(metadata['file'])
		show_timeline_editor()
	elif metadata['editor'] == 'Character':
		if not character_editor.is_selected(metadata['file']):
			character_editor.load_character(metadata['file'])
		show_character_editor()
	elif metadata['editor'] == 'Definition':
		if not definition_editor.is_selected(metadata['id']):
			definition_editor.visible = true
			definition_editor.load_definition(metadata['id'])
		show_definition_editor()
	elif metadata['editor'] == 'Theme':
		theme_editor.load_theme(metadata['file'])
		show_theme_editor()
	elif metadata['editor'] == 'Settings':
		settings_editor.update_data()
		show_settings_editor()
	else:
		hide_all_editors()

func show_character_editor():
	emit_signal("editor_selected", 'character')
	character_editor.visible = true
	timeline_editor.visible = false
	definition_editor.visible = false
	theme_editor.visible = false
	settings_editor.visible = false
	empty_editor.visible = false


func show_timeline_editor():
	emit_signal("editor_selected", 'timeline')
	character_editor.visible = false
	timeline_editor.visible = true
	definition_editor.visible = false
	theme_editor.visible = false
	settings_editor.visible = false
	empty_editor.visible = false


func show_definition_editor():
	emit_signal("editor_selected", 'definition')
	character_editor.visible = false
	timeline_editor.visible = false
	definition_editor.visible = true
	theme_editor.visible = false
	settings_editor.visible = false
	empty_editor.visible = false


func show_theme_editor():
	emit_signal("editor_selected", 'theme')
	character_editor.visible = false
	timeline_editor.visible = false
	definition_editor.visible = false
	theme_editor.visible = true
	settings_editor.visible = false
	empty_editor.visible = false


func show_settings_editor():
	emit_signal("editor_selected", 'theme')
	character_editor.visible = false
	timeline_editor.visible = false
	definition_editor.visible = false
	theme_editor.visible = false
	settings_editor.visible = true
	empty_editor.visible = false


func hide_all_editors():
	emit_signal("editor_selected", 'none')
	character_editor.visible = false
	timeline_editor.visible = false
	definition_editor.visible = false
	theme_editor.visible = false
	settings_editor.visible = false
	empty_editor.visible = true


## *****************************************************************************
##					 CONTEXT POPUPS on RMB SELECT
## *****************************************************************************

func create_rmb_context_menus():
	var timeline_popup = PopupMenu.new()
	timeline_popup.add_icon_item(get_icon("Filesystem", "EditorIcons"), 'Show in File Manager')
	timeline_popup.add_icon_item(get_icon("ActionCopy", "EditorIcons"), 'Copy Timeline Name')
	timeline_popup.add_icon_item(get_icon("Remove", "EditorIcons"), 'Remove Timeline')
	add_child(timeline_popup)
	rmb_popup_menus["Timeline"] = timeline_popup
	
	var character_popup = PopupMenu.new()
	character_popup.add_icon_item(get_icon("Filesystem", "EditorIcons"), 'Show in File Manager')
	character_popup.add_icon_item(get_icon("Remove", "EditorIcons"), 'Remove Character')
	add_child(character_popup)
	rmb_popup_menus["Character"] = character_popup
	
	var theme_popup = PopupMenu.new()
	theme_popup.add_icon_item(get_icon("Filesystem", "EditorIcons"), 'Show in File Manager')
	theme_popup.add_icon_item(get_icon("Duplicate", "EditorIcons"), 'Duplicate Theme')
	theme_popup.add_icon_item(get_icon("Remove", "EditorIcons"), 'Remove Theme')
	add_child(theme_popup)
	rmb_popup_menus["Theme"] = theme_popup
	
	var definition_popup = PopupMenu.new()
	definition_popup.add_icon_item(get_icon("Edit", "EditorIcons"), 'Edit Definitions File')
	definition_popup.add_icon_item(get_icon("Remove", "EditorIcons"), 'Remove Definition')
	add_child(definition_popup)
	rmb_popup_menus["Definition"] = definition_popup
	
	## FOLDER / ROOT ITEMS
	var timeline_folder_popup = PopupMenu.new()
	timeline_folder_popup.add_icon_item(get_icon("Add", "EditorIcons") ,'Add Timeline')
	timeline_folder_popup.add_icon_item(get_icon("ToolAddNode", "EditorIcons") ,'Create Subfolder')
	timeline_folder_popup.add_icon_item(get_icon("Remove", "EditorIcons") ,'Delete Folder')
	add_child(timeline_folder_popup)
	rmb_popup_menus['Timeline Root'] = timeline_folder_popup
	
	var character_folder_popup = PopupMenu.new()
	character_folder_popup.add_icon_item(get_icon("Add", "EditorIcons") ,'Add Character')
	add_child(character_folder_popup)
	rmb_popup_menus['Character Root'] = character_folder_popup
	
	var theme_folder_popup = PopupMenu.new()
	theme_folder_popup.add_icon_item(get_icon("Add", "EditorIcons") ,'Add Theme')
	add_child(theme_folder_popup)
	rmb_popup_menus["Theme Root"] = theme_folder_popup
	
	var definition_folder_popup = PopupMenu.new()
	definition_folder_popup.add_icon_item(get_icon("Add", "EditorIcons") ,'Add Definition')
	add_child(definition_folder_popup)
	rmb_popup_menus["Definition Root"] = definition_folder_popup
	
	
	# Connecting context menus
	timeline_popup.connect('id_pressed', self, '_on_TimelinePopupMenu_id_pressed')
	character_popup.connect('id_pressed', self, '_on_CharacterPopupMenu_id_pressed')
	theme_popup.connect('id_pressed', self, '_on_ThemePopupMenu_id_pressed')
	definition_popup.connect('id_pressed', self, '_on_DefinitionPopupMenu_id_pressed')
	
	timeline_folder_popup.connect('id_pressed', self, '_on_TimelineRootPopupMenu_id_pressed')
	character_folder_popup.connect('id_pressed', self, '_on_CharacterRootPopupMenu_id_pressed')
	theme_folder_popup.connect('id_pressed', self, '_on_ThemeRootPopupMenu_id_pressed')
	definition_folder_popup.connect('id_pressed', self, '_on_DefinitionRootPopupMenu_id_pressed')

func _on_item_rmb_selected(position):
	var item = get_selected().get_metadata(0)
	if item.has('editor'):
		rmb_popup_menus[item["editor"]].rect_position = get_viewport().get_mouse_position()
		rmb_popup_menus[item["editor"]].popup()

# Timeline context menu
func _on_TimelinePopupMenu_id_pressed(id):
	if id == 0: # View files
		OS.shell_open(ProjectSettings.globalize_path(DialogicResources.get_path('TIMELINE_DIR')))
	if id == 1: # Copy to clipboard
		OS.set_clipboard(editor_reference.get_node("MainPanel/TimelineEditor").timeline_name)
	if id == 2: # Remove
		editor_reference.get_node('RemoveTimelineConfirmation').popup_centered()

# Character context menu
func _on_CharacterPopupMenu_id_pressed(id):
	if id == 0:
		OS.shell_open(ProjectSettings.globalize_path(DialogicResources.get_path('CHAR_DIR')))
	if id == 1:
		editor_reference.get_node('RemoveCharacterConfirmation').popup_centered()


# Theme context menu
func _on_ThemePopupMenu_id_pressed(id):
	if id == 0:
		OS.shell_open(ProjectSettings.globalize_path(DialogicResources.get_path('THEME_DIR')))
	if id == 1:
		var filename = editor_reference.get_node('MainPanel/MasterTreeContainer/MasterTree').get_selected().get_metadata(0)['file']
		if (filename.begins_with('theme-')):
			editor_reference.theme_editor.duplicate_theme(filename)
	if id == 2:
		editor_reference.get_node('RemoveThemeConfirmation').popup_centered()


# Definition context menu
func _on_DefinitionPopupMenu_id_pressed(id):
	if id == 0:
		var paths = DialogicResources.get_config_files_paths()
		OS.shell_open(ProjectSettings.globalize_path(paths['DEFAULT_DEFINITIONS_FILE']))
	if id == 1:
		editor_reference.get_node('RemoveDefinitionConfirmation').popup_centered()

func get_selected_folder(root : String):
	if not get_selected():
		return root
	var current_path:String = get_item_path(get_selected())
	if not "Root" in get_selected().get_metadata(0)['editor']:
		current_path = DialogicUtil.get_parent_path(current_path)
	if not current_path.begins_with(root):
		return root
	return current_path
	
func get_item_path(item: TreeItem) -> String:
	print("create path for ", item)
	if item == null:
		return ''
	return create_item_path_recursive(item, "").trim_suffix("/")

func create_item_path_recursive(item:TreeItem, path:String) -> String:
	path = item.get_text(0)+'/'+path
	if item.get_parent() == get_root():
		return path
	else:
		path = create_item_path_recursive(item.get_parent(), path)
	return path

# Timeline Root context menu
func _on_TimelineRootPopupMenu_id_pressed(id):
	var item = get_selected()
	print(item)
	if id == 0: # Add Timeline
		print(item)
		new_timeline()
	if id == 1: # add subfolder
		DialogicUtil.add_folder(get_item_path(item), "New Folder "+str(OS.get_unix_time()))
		build_timelines()
	if id == 2: # remove folder and substuff
		if get_selected().get_parent() == get_root():
			return
		editor_reference.get_node('RemoveFolderConfirmation').popup_centered()
	print(get_selected())

func new_timeline():
	var timeline = editor_reference.get_node('MainPanel/TimelineEditor').create_timeline()
	var folder = get_selected_folder("Timelines")
	print(folder)
	DialogicUtil.add_file_to_folder(folder, timeline['metadata']['file'])
	build_timelines(timeline['metadata']['file'])

# Character Root context menu
func _on_CharacterRootPopupMenu_id_pressed(id):
	if id == 0: # Add Character
		editor_reference.get_node('MainPanel/CharacterEditor').new_character()

# Theme Root context menu
func _on_ThemeRootPopupMenu_id_pressed(id):
	if id == 0: # Add Theme
		editor_reference.get_node('MainPanel/ThemeEditor').new_theme()

# Definition Root context menu
func _on_DefinitionRootPopupMenu_id_pressed(id):
	if id == 0: # Add Definition
		editor_reference.get_node('MainPanel/DefinitionEditor').new_definition()

func remove_selected():
	var item = get_selected()
	item.free()
	timelines_tree.select(0)
	settings_editor.update_data()


func refresh_timeline_list():
	#print('update timeline list')
	pass


func _on_renamer_reset_timeout():
	get_selected().set_editable(0, false)


func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.is_pressed() and event.doubleclick:
			var item = get_selected()
			var metadata = item.get_metadata(0)
			if metadata.has("editable") and metadata["editable"]:
				item_path_before_edit = get_item_path(item)
				item.set_editable(0, true)
				$RenamerReset.start(0.5)


func _on_item_edited():
	var item = get_selected()
	var metadata = item.get_metadata(0)
	if metadata['editor'] == 'Timeline':
		timeline_editor.timeline_name = item.get_text(0)
		save_current_resource()
		build_timelines(metadata['file'])
	if metadata['editor'] == 'Theme':
		DialogicResources.set_theme_value(metadata['file'], 'settings', 'name', item.get_text(0))
		build_themes(metadata['file'])
	if metadata['editor'] == 'Character':
		character_editor.nodes['name'].text = item.get_text(0)
		save_current_resource()
		build_characters(metadata['file'])
	if metadata['editor'] == 'Definition':
		definition_editor.nodes['name'].text = item.get_text(0)
		# Not sure why this signal doesn't triggers
		definition_editor._on_name_changed(item.get_text(0))
		save_current_resource()
		build_definitions(metadata['id'])
	
	if metadata['editor'] == 'Timeline Root':
		DialogicUtil.rename_folder(item_path_before_edit, item.get_text(0))

func _on_autosave_timeout():
	save_current_resource()
	
	
func _on_filter_tree_edit_changed(value):
	filter_tree_term = value
	build_timelines()
	build_themes()
	build_characters()
	build_definitions()


func save_current_resource():
	var root = get_node('../..') # This is the same as the editor_reference
	if root.visible: #Only save if the editor is open
		var item: TreeItem = get_selected()
		var metadata: Dictionary
		if item != null:
			metadata = item.get_metadata(0)
			if metadata['editor'] == 'Timeline':
				timeline_editor.save_timeline()
			if metadata['editor'] == 'Character':
				character_editor.save_character()
			if metadata['editor'] == 'Definition':
				definition_editor.save_definition()
			# Note: Theme files auto saves on change


func select_timeline_item(timeline_name):
	if (timeline_name == ''):
		return

	var main_item = tree.get_root().get_children()
	
	# wow, godots tree traversal is extremly odd, or I just don't get it
	while (main_item):
		
		if (main_item == null):
			break
			
		if (main_item.has_method("get_text") && main_item.get_text(0) == "Timelines"):
			var item = main_item.get_children()
			while (item):
							
				if (not item.has_method("get_metadata")):
					item = item.get_next()
					continue
			
				var meta = item.get_metadata(0)
		
				if (meta == null):
					item = item.get_next()
					continue
		
				if (not meta.has("editor") or meta["editor"] != "Timeline"):
					item = item.get_next()
					continue
			
				# search for filename
				if (meta.has("file") and meta["file"] == timeline_name):
					# select this one
					item.select(0)
					return;
			
				# search for name
				if (meta.has("name") and meta["name"] == timeline_name):
					# select this one
					item.select(0)
					return;
	
				item = item.get_next()
			break
		else:
			main_item = main_item.get_next()
			
	# fallback
	hide_all_editors()
	pass

