tool
extends Tree

var editor_reference
onready var timeline_editor = get_node('../../TimelineEditor')
onready var character_editor = get_node('../../CharacterEditor')
onready var value_editor = get_node('../../ValueEditor')
onready var glossary_entry_editor = get_node('../../GlossaryEntryEditor')
onready var settings_editor = get_node('../../SettingsEditor')
onready var theme_editor = get_node('../../ThemeEditor')
onready var documentation_viewer = get_node('../../DocumentationViewer')
onready var empty_editor = get_node('../../Empty')
onready var filter_tree_edit = get_node('../FilterMasterTreeEdit')

onready var tree = self

var timeline_icon
var character_icon
var theme_icon
var definition_icon
var glossary_icon
var documentation_icon

var timelines_tree
var characters_tree
var definitions_tree
var themes_tree
var settings_tree
var documentation_tree


var item_path_before_edit = ""

# dragging items
var dragging_item = null
var drag_preview = load("res://addons/dialogic/Editor/MasterTree/DragPreview.tscn")

var rmb_popup_menus = {}

var filter_tree_term = ''

signal editor_selected(selected)

func _ready():
	editor_reference = find_parent('EditorView')

	# Tree Settings
	allow_rmb_select = true
	var root = tree.create_item()
	tree.set_hide_root(true)
	
	# Scaling
	var modifier = ''
	var _scale = DialogicUtil.get_editor_scale(self)
	
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
	
	# Icons
	timeline_icon = load("res://addons/dialogic/Images/Resources/timeline" + modifier + ".svg")
	character_icon = load("res://addons/dialogic/Images/Resources/character" + modifier + ".svg")
	theme_icon = load("res://addons/dialogic/Images/Resources/theme" + modifier + ".svg")
	definition_icon = load("res://addons/dialogic/Images/Resources/definition" + modifier + ".svg")
	glossary_icon = get_icon("ListSelect", "EditorIcons")
	
	# Creating the root items
	for tree_info in [
		# variable		 name		  editor
		["Timelines", "Timeline Root"],
		["Characters", "Character Root"],
		["Definitions", "Definition Root"],
		["Themes", "Theme Root"],
			]:
		# create tree item
		var sub_tree = tree.create_item(root)
		# set the item
		sub_tree.set_icon(0, get_icon("Folder", "EditorIcons"))
		sub_tree.set_icon_modulate(0, get_color("folder_icon_modulate", "FileDialog"))
		# set info
		sub_tree.set_text(0, tree_info[0])
		sub_tree.collapsed = DialogicUtil.get_folder_meta(tree_info[0], 'folded')
		sub_tree.set_metadata(0, {'editor': tree_info[1], 'path': '', 'step': 0, "name": "", 'category': tree_info[0]})
		# set the correct tree variable
		match tree_info[0]:
			"Timelines":
				timelines_tree = sub_tree
			"Characters":
				characters_tree = sub_tree
			"Definitions":
				definitions_tree = sub_tree
			"Themes":
				themes_tree = sub_tree
	
	settings_tree = tree.create_item(root)
	settings_tree.set_text(0, editor_reference.dialogicTranslator.translate("Settings"))
	settings_tree.set_icon(0, get_icon("GDScript", "EditorIcons"))
	settings_tree.set_metadata(0, {'editor': 'Settings'})
	
	documentation_tree = tree.create_item(root)
	documentation_tree.set_text(0, editor_reference.dialogicTranslator.translate("Help"))
	documentation_tree.set_icon(0, get_icon("HelpSearch", "EditorIcons"))
	documentation_tree.set_metadata(0, {'editor': 'Documentation Root', 'name':'Start', 'path':'Welcome.md'})
	
	
	# creates the context menus
	create_rmb_context_menus()
	
	# connecting signals
	connect('item_selected', self, '_on_item_selected')
	connect('item_rmb_selected', self, '_on_item_rmb_selected')
	connect('item_collapsed', self, '_on_item_collapsed')
	connect('gui_input', self, '_on_gui_input')
	connect('item_edited', self, '_on_item_edited')
	$RenamerReset.connect("timeout", self, '_on_renamer_reset_timeout')
	filter_tree_edit.connect("text_changed", self, '_on_filter_tree_edit_changed')
	
	# build all tree parts
	build_full_tree()
	
	# Adding docs
	build_documentation()
	
	# Default empty screen.
	hide_all_editors() 
	
	# AutoSave timer
	$AutoSave.connect("timeout", self, '_on_autosave_timeout')
	$AutoSave.start(0.5)

## *****************************************************************************
##						BUILDING THE TREE
## *****************************************************************************

func build_full_tree(selected_item: String = ''):

	
	# Adding timelines
	build_flat_tree_items("Timelines")
	# Adding characters
	build_flat_tree_items("Characters")
	# Adding Definitions
	build_flat_tree_items("Definitions")
	# Adding Themes
	build_flat_tree_items("Themes")
	
	# force redraw control
	update()
	
func build_flat_tree_items(current_tree: String=''):
	current_tree = current_tree + "_Array"
	#break if the flat_structure isn't built yet so it doesn't throw an error, which happens at plugin start
	if !current_tree in editor_reference.flat_structure:
		return
		
	var current_root
	var editor
	var depth_stack = []
	
	match (current_tree):
		"Timelines_Array":
			current_root = timelines_tree
			_clear_tree_children(timelines_tree)
			editor = "Timeline Root"
		"Characters_Array": 
			current_root = characters_tree
			_clear_tree_children(characters_tree)
			editor = "Character Root"
		"Definitions_Array":
			current_root = definitions_tree
			_clear_tree_children(definitions_tree)
			editor = "Definition Root"
		"Themes_Array":
			current_root = themes_tree
			_clear_tree_children(themes_tree)
			editor = "Theme Root"
	
	depth_stack.push_back({"path": "/", "object": current_root})
	
	var step = -1
	for entry in editor_reference.flat_structure[current_tree]:
		step = step + 1
		#Skip the root folder 
		if entry['key'] == "/.":
			continue
		
		if (filter_tree_term == '') or (filter_tree_term.to_lower() in entry['key'].to_lower()):
			pass
		else:
			continue
		
		#check where we are in the stack
		while !(depth_stack[-1]["path"] in entry['key']) and depth_stack.size() > 1:
			var popped = depth_stack.pop_back()
		
		current_root = depth_stack[-1]["object"]
		
		if "folded" in entry['value']:
			# folder add
			var folder_item:TreeItem= tree.create_item(current_root)
			# set text and icon
			var folder_name = entry['key'].split("/")[-2]
			folder_item.set_text(0, folder_name)
			folder_item.set_tooltip(0, str(step) + ": " + entry['key'])
			folder_item.set_icon(0, get_icon("Folder", "EditorIcons"))
			folder_item.set_icon_modulate(0, get_color("folder_icon_modulate", "FileDialog"))
			# set metadata
			var stripped_path = entry['key'].rstrip("/.").rstrip(folder_name)
			folder_item.set_metadata(0, {'editor': editor,'editortype': 'folder', 'editable': true, "path": stripped_path, "name": folder_name, "category": current_tree.rstrip('_Array'), 'step': step})
			# set collapsed
			folder_item.collapsed = entry['value']['folded']
			current_root = folder_item	
			depth_stack.push_back({"path": entry['key'].rstrip("."), "object": folder_item})
			
		else:
			#file add
			var resource_data = entry['value']
			
			var item = tree.create_item(current_root)
			resource_data['category']= current_tree.rstrip('_Array')
			resource_data['editortype'] = 'file'
			# set the text
			if resource_data.has('name'):
				item.set_text(0, resource_data['name'])
				resource_data['path'] = entry['key'].rstrip(resource_data['name'])
			else:
				item.set_text(0, resource_data['file'])
				resource_data['path'] = entry['key'].rstrip(resource_data['file'])
				resource_data['name'] = resource_data['file']
			if not get_constant("dark_theme", "Editor"):
				item.set_icon_modulate(0, get_color("property_color", "Editor"))
			# set it as editable
			resource_data['editable'] = true
			# resource specific changes
			match current_tree:
				"Timelines_Array":
					item.set_icon(0, timeline_icon)
					resource_data['editor'] = 'Timeline'
					resource_data['step'] = step
				"Characters_Array":
					item.set_icon(0, character_icon)
					resource_data['editor'] = 'Character'
					resource_data['step'] = step
					if resource_data.has('color'):
						item.set_icon_modulate(0, resource_data['color'])
				"Definitions_Array":
					if resource_data['type'] == 0:
						item.set_icon(0, definition_icon)
						resource_data['editor'] = 'Value'
						resource_data['step'] = step
					else:
						item.set_icon(0, glossary_icon)
						resource_data['editor'] = 'GlossaryEntry'
						resource_data['step'] = step
				"Themes_Array":
					item.set_icon(0, theme_icon)
					resource_data['editor'] = 'Theme'
					resource_data['step'] = step
			
			item.set_metadata(0, resource_data)
			item.set_tooltip(0, str(step) + ": " +entry['key'])
	

func _clear_tree_children(parent: TreeItem):
	while parent.get_children() != null:
		parent.get_children().free()


func build_resource_folder(parent_folder_item:TreeItem, folder_data:Dictionary, selected_item:String, folder_editor:String, resource_type: String):
	## BUILD ALL THE FOLDER ITEMS (by calling this method for them)
	for folder in folder_data["folders"].keys():
		var folder_item = _add_folder_item(parent_folder_item, folder, folder_editor, folder_data["folders"][folder]['metadata'])
		var contains_something = build_resource_folder(folder_item, folder_data["folders"][folder], selected_item, folder_editor, resource_type)
		if (not filter_tree_term.empty()) and (not contains_something):
			folder_item.free()
	
	## BUILD ALL THE FILE ITEMS
	for file in folder_data["files"]:
		# get the file_metadata
		var file_metadata
		match resource_type:
			"Timeline":
				file_metadata = DialogicUtil.get_timeline_dict()[file]
			"Character":
				file_metadata = DialogicUtil.get_characters_dict()[file]
			"Theme":
				file_metadata = DialogicUtil.get_theme_dict()[file]
			"Definition":
				file_metadata = DialogicUtil.get_default_definitions_dict()[file]
		
		# add the file item (considering the filter_term)
		if (filter_tree_term == '') or (filter_tree_term.to_lower() in file_metadata['name'].to_lower()):
			_add_resource_item(resource_type, parent_folder_item, file_metadata, not selected_item.empty() and file == selected_item)
	
	# force redraw control
	update()
	
	return true if (parent_folder_item.get_children() != null) else false


func _add_folder_item(parent_item: TreeItem, folder_name: String, editor:String, meta_folder_info:Dictionary):
	# create item
	var folder_item:TreeItem= tree.create_item(parent_item)

	var parent_path = parent_item.get_metadata(0)['path']
	var current_tree = parent_item.get_metadata(0)['category'].rstrip("_Array")
	# set text and icon
	folder_item.set_text(0, folder_name)
	folder_item.set_icon(0, get_icon("Folder", "EditorIcons"))
	folder_item.set_icon_modulate(0, get_color("folder_icon_modulate", "FileDialog"))
	# set metadata
	folder_item.set_metadata(0, {'editor': editor,'editortype':'folder', 'editable': true, "name": folder_name, "path:": parent_path, "category": current_tree})
	# set collapsed
	if filter_tree_term.empty():
		folder_item.collapsed = meta_folder_info['folded']
	# add to flat table
	editor_reference.editor_reference.flat_structure[parent_path + "/"  + "folder_name" + "/."] = {"color": null, "folded": folder_item.collapsed}
	return folder_item


func _add_resource_item(resource_type, parent_item, resource_data, select):
	resource_data['category'] = resource_type
	resource_data['editortype'] = 'file'
	# create item
	var item = tree.create_item(parent_item)
	# set the text
	if resource_data.has('name'):
		item.set_text(0, resource_data['name'])
	else:
		item.set_text(0, resource_data['file'])
	if not get_constant("dark_theme", "Editor"):
		item.set_icon_modulate(0, get_color("property_color", "Editor"))
	# set it as editable
	resource_data['editable'] = true
	# resource specific changes
	match resource_type:
		"Timeline":
			item.set_icon(0, timeline_icon)
			resource_data['editor'] = 'Timeline'
		"Character":
			item.set_icon(0, character_icon)
			resource_data['editor'] = 'Character'
			if resource_data.has('color'):
				item.set_icon_modulate(0, resource_data['color'])
		"Definition":
			if resource_data['type'] == 0:
				item.set_icon(0, definition_icon)
				resource_data['editor'] = 'Value'
			else:
				item.set_icon(0, glossary_icon)
				resource_data['editor'] = 'GlossaryEntry'
		"Theme":
			item.set_icon(0, theme_icon)
			resource_data['editor'] = 'Theme'
	
	item.set_metadata(0, resource_data)
	
	if select:
		item.select(0)


## TIMELINES
func build_timelines(selected_item: String=''):
	_clear_tree_children(timelines_tree)
	
	build_flat_tree_items("Timelines")

## CHARACTERS
func build_characters(selected_item: String=''):
	_clear_tree_children(characters_tree)
	
	build_flat_tree_items("Characters")

## DEFINTIONS
func build_definitions(selected_item: String=''):
	_clear_tree_children(definitions_tree)
	
	build_flat_tree_items("Definitions")

## THEMES
func build_themes(selected_item: String=''):
	_clear_tree_children(themes_tree)
	
	build_flat_tree_items("Themes")

func _on_item_collapsed(item: TreeItem):
	if filter_tree_term.empty() and item != null and 'Root' in item.get_metadata(0)['editor'] and not 'Documentation' in item.get_metadata(0)['editor']:
		DialogicUtil.set_folder_meta(editor_reference.flat_structure, item.get_metadata(0), 'folded', item.collapsed)

func build_documentation(selected_item: String=''):
	var child = documentation_tree.get_children()
	while child:
		child.call_recursive("call_deferred", "free")
		child = child.get_next()
	$DocsTreeHelper.build_documentation_tree(self, documentation_tree, {'editor':'Documentation Root', 'editable':false}, {'editor':'Documentation', 'editable':false}, filter_tree_term)
	call_deferred("update")
	
## *****************************************************************************
##						 OPENING EDITORS
## *****************************************************************************

func _on_item_selected():
	# TODO: Ideally I would perform a "save" here before opening the next
	#       resource. Unfortunately there has been so many bugs doing that 
	#       that I'll revisit it in the future. 
	#       save_current_resource()
	var metadata = get_selected().get_metadata(0)
	match metadata['editor']:
		'Timeline':
			# Remember to also update this on the `inspector_timeline_picker.gd`
			timeline_editor.batches.clear()
			timeline_editor.load_timeline(metadata['file'])
			show_timeline_editor()
		'Character':
			character_editor.load_character(metadata['file'])
			character_editor.set_meta('tree_position', metadata['step'])
			show_character_editor()
		'Value':
			value_editor.load_definition(metadata['id'])
			show_value_editor()
		'GlossaryEntry':
			glossary_entry_editor.load_definition(metadata['id'])
			show_glossary_entry_editor()
		'Theme':
			show_theme_editor()
			theme_editor.load_theme(metadata['file'])
		'Settings':
			settings_editor.update_data()
			show_settings_editor()
		'Documentation', 'Documentation Root':
			if metadata['path']:
				documentation_viewer.load_page(metadata['path'])
				show_documentatio_editor()
			get_selected().collapsed = false
		_:
			hide_all_editors()

func show_timeline_editor():
	emit_signal("editor_selected", 'timeline')
	hide_editors()
	timeline_editor.visible = true

func show_character_editor():
	emit_signal("editor_selected", 'character')
	hide_editors()
	character_editor.visible = true

func show_value_editor():
	emit_signal("editor_selected", 'definition')
	hide_editors()
	value_editor.visible = true

func show_glossary_entry_editor():
	emit_signal("editor_selected", 'glossary_entry')
	hide_editors()
	glossary_entry_editor.visible = true

func show_theme_editor():
	emit_signal("editor_selected", 'theme')
	hide_editors()
	theme_editor.visible = true


func show_settings_editor():
	emit_signal("editor_selected", 'theme')
	hide_editors()
	settings_editor.visible = true


func show_documentatio_editor():
	emit_signal("editor_selected", "documentation")
	hide_editors()
	documentation_viewer.visible = true


func hide_all_editors():
	emit_signal("editor_selected", 'none')
	hide_editors()
	empty_editor.visible = true


func hide_editors():
	character_editor.visible = false
	timeline_editor.visible = false
	value_editor.visible = false
	glossary_entry_editor.visible = false
	theme_editor.visible = false
	settings_editor.visible = false
	documentation_viewer.visible = false
	empty_editor.visible = false

## *****************************************************************************
##					 CONTEXT POPUPS on RMB SELECT
## *****************************************************************************

func create_rmb_context_menus():
	
	var timeline_popup = PopupMenu.new()
	timeline_popup.add_icon_item(get_icon("Filesystem", "EditorIcons"), editor_reference.dialogicTranslator.translate('Show in File Manager'))
	timeline_popup.add_icon_item(get_icon("ActionCopy", "EditorIcons"), editor_reference.dialogicTranslator.translate('Copy Timeline Name'))
	timeline_popup.add_icon_item(get_icon("Rename", "EditorIcons"), editor_reference.dialogicTranslator.translate('Copy File Name'))
	timeline_popup.add_icon_item(get_icon("Remove", "EditorIcons"), editor_reference.dialogicTranslator.translate('Remove Timeline'))
	add_child(timeline_popup)
	add_rmb_popup_style(timeline_popup)
	rmb_popup_menus["Timeline"] = timeline_popup
	
	var character_popup = PopupMenu.new()
	character_popup.add_icon_item(get_icon("Filesystem", "EditorIcons"), editor_reference.dialogicTranslator.translate('Show in File Manager'))
	character_popup.add_icon_item(get_icon("Rename", "EditorIcons"), editor_reference.dialogicTranslator.translate('Copy File Name'))
	character_popup.add_icon_item(get_icon("Remove", "EditorIcons"), editor_reference.dialogicTranslator.translate('Remove Character'))
	add_child(character_popup)
	add_rmb_popup_style(character_popup)
	rmb_popup_menus["Character"] = character_popup
	
	var theme_popup = PopupMenu.new()
	theme_popup.add_icon_item(get_icon("Filesystem", "EditorIcons"), editor_reference.dialogicTranslator.translate('Show in File Manager'))
	theme_popup.add_icon_item(get_icon("Rename", "EditorIcons"), editor_reference.dialogicTranslator.translate('Copy File Name'))
	theme_popup.add_icon_item(get_icon("Duplicate", "EditorIcons"), editor_reference.dialogicTranslator.translate('Duplicate Theme'))
	theme_popup.add_icon_item(get_icon("Remove", "EditorIcons"), editor_reference.dialogicTranslator.translate('Remove Theme'))
	add_child(theme_popup)
	add_rmb_popup_style(theme_popup)
	rmb_popup_menus["Theme"] = theme_popup
	
	var definition_popup = PopupMenu.new()
	definition_popup.add_icon_item(get_icon("Edit", "EditorIcons"), editor_reference.dialogicTranslator.translate('Edit Definitions File'))
	definition_popup.add_icon_item(get_icon("Rename", "EditorIcons"), editor_reference.dialogicTranslator.translate('Copy Definition ID'))
	definition_popup.add_icon_item(get_icon("Remove", "EditorIcons"), editor_reference.dialogicTranslator.translate('Remove Definition entry'))
	add_child(definition_popup)
	add_rmb_popup_style(definition_popup)
	rmb_popup_menus["Value"] = definition_popup
	rmb_popup_menus["GlossaryEntry"] = definition_popup
	
	## FOLDER / ROOT ITEMS
	var timeline_folder_popup = PopupMenu.new()
	timeline_folder_popup.add_icon_item(get_icon("Add", "EditorIcons") ,editor_reference.dialogicTranslator.translate('Add Timeline'))
	timeline_folder_popup.add_icon_item(get_icon("Folder", "EditorIcons") ,editor_reference.dialogicTranslator.translate('Create Subfolder'))
	timeline_folder_popup.add_icon_item(get_icon("Remove", "EditorIcons") ,editor_reference.dialogicTranslator.translate('Delete Folder'))
	add_child(timeline_folder_popup)
	add_rmb_popup_style(timeline_folder_popup)
	rmb_popup_menus['Timeline Root'] = timeline_folder_popup
	
	var character_folder_popup = PopupMenu.new()
	character_folder_popup.add_icon_item(get_icon("Add", "EditorIcons") ,editor_reference.dialogicTranslator.translate('Add Character'))
	character_folder_popup.add_icon_item(get_icon("Folder", "EditorIcons") ,editor_reference.dialogicTranslator.translate('Create Subfolder'))
	character_folder_popup.add_icon_item(get_icon("Remove", "EditorIcons") ,editor_reference.dialogicTranslator.translate('Delete Folder'))
	add_child(character_folder_popup)
	add_rmb_popup_style(character_folder_popup)
	rmb_popup_menus['Character Root'] = character_folder_popup
	
	var theme_folder_popup = PopupMenu.new()
	theme_folder_popup.add_icon_item(get_icon("Add", "EditorIcons") ,editor_reference.dialogicTranslator.translate('Add Theme'))
	theme_folder_popup.add_icon_item(get_icon("Folder", "EditorIcons") ,editor_reference.dialogicTranslator.translate('Create Subfolder'))
	theme_folder_popup.add_icon_item(get_icon("Remove", "EditorIcons") ,editor_reference.dialogicTranslator.translate('Delete Folder'))
	add_child(theme_folder_popup)
	add_rmb_popup_style(theme_folder_popup)
	rmb_popup_menus["Theme Root"] = theme_folder_popup
	
	var definition_folder_popup = PopupMenu.new()
	definition_folder_popup.add_icon_item(get_icon("Add", "EditorIcons") ,editor_reference.dialogicTranslator.translate('Add Value'))
	definition_folder_popup.add_icon_item(get_icon("Add", "EditorIcons") ,editor_reference.dialogicTranslator.translate('Add Glossary Entry'))
	definition_folder_popup.add_icon_item(get_icon("Folder", "EditorIcons") ,editor_reference.dialogicTranslator.translate('Create Subfolder'))
	definition_folder_popup.add_icon_item(get_icon("Remove", "EditorIcons") ,editor_reference.dialogicTranslator.translate('Delete Folder'))
	add_child(definition_folder_popup)
	add_rmb_popup_style(definition_folder_popup)
	rmb_popup_menus["Definition Root"] = definition_folder_popup
	
	var documentation_folder_popup = PopupMenu.new()
	documentation_folder_popup.add_icon_item(get_icon("Edit", "EditorIcons") ,editor_reference.dialogicTranslator.translate('Toggle Editing Tools'))
	add_child(documentation_folder_popup)
	add_rmb_popup_style(documentation_folder_popup)
	rmb_popup_menus["Documentation Root"] = documentation_folder_popup
	
	var documentation_popup = PopupMenu.new()
	documentation_popup.add_icon_item(get_icon("Edit", "EditorIcons") ,editor_reference.dialogicTranslator.translate('Toggle Editing Tools'))
	add_child(documentation_popup)
	add_rmb_popup_style(documentation_popup)
	rmb_popup_menus["Documentation"] = documentation_popup
	
	# Connecting context menus
	timeline_popup.connect('id_pressed', self, '_on_TimelinePopupMenu_id_pressed')
	character_popup.connect('id_pressed', self, '_on_CharacterPopupMenu_id_pressed')
	theme_popup.connect('id_pressed', self, '_on_ThemePopupMenu_id_pressed')
	definition_popup.connect('id_pressed', self, '_on_DefinitionPopupMenu_id_pressed')
	documentation_popup.connect('id_pressed', self, '_on_DocumentationPopupMenu_id_pressed')
		
	timeline_folder_popup.connect('id_pressed', self, '_on_TimelineRootPopupMenu_id_pressed')
	character_folder_popup.connect('id_pressed', self, '_on_CharacterRootPopupMenu_id_pressed')
	theme_folder_popup.connect('id_pressed', self, '_on_ThemeRootPopupMenu_id_pressed')
	definition_folder_popup.connect('id_pressed', self, '_on_DefinitionRootPopupMenu_id_pressed')
	documentation_folder_popup.connect('id_pressed', self, '_on_DocumentationPopupMenu_id_pressed')

func add_rmb_popup_style(popup):
	var menu_background = load("res://addons/dialogic/Editor/Events/styles/ResourceMenuPanelBackground.tres")
	menu_background.bg_color = get_color("base_color", "Editor")
	
	popup.add_stylebox_override('panel', menu_background)
	popup.add_stylebox_override('hover', StyleBoxEmpty.new())
	popup.add_color_override('font_color_hover', get_color("accent_color", "Editor"))

func _on_item_rmb_selected(position):
	var item = get_selected().get_metadata(0)
	if item.has('editor'):
		rmb_popup_menus[item["editor"]].rect_position = get_viewport().get_mouse_position()
		rmb_popup_menus[item["editor"]].popup()

## item paths (for the folder structure management)
# this returns the folder path, or the folder the item is in (if it's not a folder)
# it makes sure the folder_path begins with @root!
func get_item_folder(item: TreeItem, root : String):
	if not item:
		return root
	var current_path:String = get_item_path(item)['path']
	if not "Root" in item.get_metadata(0)['editor']:
		current_path = DialogicUtil.get_parent_path(current_path)
	if not current_path.begins_with(root):
		return root
	return current_path


func get_item_path(item: TreeItem) -> Dictionary:
	if item == null:
		return {'path': "", 'step': '0'}
	
	if 	!'path' in item.get_metadata(0):
		return {'path': "/", 'step': '0'}
	return {'path': item.get_metadata(0)['path'], 'step': item.get_metadata(0)['step']}


func create_item_path_recursive(item:TreeItem, path:String) -> String:
	# don't use this function directly
	# use get_item_path() or get_item_folder()
	path = item.get_text(0)+'/'+path
	if item.get_parent() == get_root():
		return path
	else:
		path = create_item_path_recursive(item.get_parent(), path)
	return path

## RESOURCE POPUPS

# Timeline context menu
func _on_TimelinePopupMenu_id_pressed(id):
	if id == 0: # View files
		OS.shell_open(ProjectSettings.globalize_path(DialogicResources.get_path('TIMELINE_DIR')))
	elif id == 1: # Copy to clipboard
		OS.set_clipboard(get_item_path(get_selected())['path'].replace('Timelines', ''))
	elif id == 2: # Copy File name
		OS.set_clipboard(get_selected().get_metadata(0).get('file'))
	elif id == 3: # Remove
		editor_reference.popup_remove_confirmation('Timeline')


# Character context menu
func _on_CharacterPopupMenu_id_pressed(id):
	if id == 0:
		OS.shell_open(ProjectSettings.globalize_path(DialogicResources.get_path('CHAR_DIR')))
	elif id == 1: # Copy File name
		OS.set_clipboard(get_selected().get_metadata(0).get('file'))
	elif id == 2: # Remove
		editor_reference.popup_remove_confirmation('Character')


# Theme context menu
func _on_ThemePopupMenu_id_pressed(id):
	if id == 0:
		OS.shell_open(ProjectSettings.globalize_path(DialogicResources.get_path('THEME_DIR')))
	elif id == 1: # Copy File name
		OS.set_clipboard(get_selected().get_metadata(0).get('file'))
	elif id == 2:
		var filename = editor_reference.get_node('MainPanel/MasterTreeContainer/MasterTree').get_selected().get_metadata(0)['file']
		theme_editor.duplicate_theme(filename)
	elif id == 3:
		editor_reference.popup_remove_confirmation('Theme')


# Definition context menu
func _on_DefinitionPopupMenu_id_pressed(id):
	if id == 0:
		var paths = DialogicResources.get_config_files_paths()
		OS.shell_open(ProjectSettings.globalize_path(paths['DEFAULT_DEFINITIONS_FILE']))
	elif id == 1: # Copy File name
		OS.set_clipboard(get_selected().get_metadata(0).get('id'))
	if id == 2:
		if value_editor.visible:
			editor_reference.popup_remove_confirmation('Value')
		elif glossary_entry_editor.visible:
			editor_reference.popup_remove_confirmation('GlossaryEntry')
	
## FOLDER POPUPS

# Timeline Folder context menu
func _on_TimelineRootPopupMenu_id_pressed(id):
	if id == 0: # Add Timeline
		new_timeline()
	if id == 1: # add subfolder
		DialogicUtil.add_folder(editor_reference.flat_structure, "Timelines", get_selected().get_metadata(0), "New Folder "+str(OS.get_unix_time()))
		build_flat_tree_items("Timelines")
	if id == 2: # remove folder and substuff
		if get_selected().get_parent() == get_root():
			return
		editor_reference.get_node('RemoveFolderConfirmation').popup_centered()


# Character Folder context menu
func _on_CharacterRootPopupMenu_id_pressed(id):
	if id == 0: # Add Character
		new_character()
	if id == 1: # add subfolder
		DialogicUtil.add_folder(editor_reference.flat_structure, "Characters", get_selected().get_metadata(0), "New Folder "+str(OS.get_unix_time()))
		
		build_flat_tree_items("Characters")
	if id == 2: # remove folder and substuff
		if get_selected().get_parent() == get_root():
			return
		editor_reference.get_node('RemoveFolderConfirmation').popup_centered()


# Definition Folder context menu
func _on_DefinitionRootPopupMenu_id_pressed(id):
	if id == 0: # Add Value Definition
		new_value_definition()
	if id == 1: # Add Glossary Definition
		new_glossary_entry()
	if id == 2: # add subfolder
		DialogicUtil.add_folder(editor_reference.flat_structure, "Definitions", get_selected().get_metadata(0), "New Folder "+str(OS.get_unix_time()))
		build_flat_tree_items("Definitions")
	if id == 3: # remove folder and substuff
		if get_selected().get_parent() == get_root():
			return
		editor_reference.get_node('RemoveFolderConfirmation').popup_centered()


# Theme Folder context menu
func _on_ThemeRootPopupMenu_id_pressed(id):
	if id == 0: # Add Theme
		new_theme()
	if id == 1: # add subfolder
		DialogicUtil.add_folder(editor_reference.flat_structure, "Themes", get_selected().get_metadata(0), "New Folder "+str(OS.get_unix_time()))
		build_flat_tree_items("Themes")
	if id == 2: # remove folder and substuff
		if get_selected().get_parent() == get_root():
			return
		editor_reference.get_node('RemoveFolderConfirmation').popup_centered()


func _on_DocumentationPopupMenu_id_pressed(id):
	if id == 0: # edit text toggled
		documentation_viewer.toggle_editing()
## *****************************************************************************
##						 CREATING AND REMOVING
## *****************************************************************************

# creates a new timeline and opens it
# it will be added to the selected folder (if it's a timeline folder) or the Timeline root folder
func new_timeline():
	var timeline = editor_reference.get_node('MainPanel/TimelineEditor').create_timeline()
	var folder = {'category':'Timelines', 'editor':'Timeline Root', 'name':'', 'path':'', 'step':0}
	if get_selected() != null:
		folder = get_selected().get_metadata(0)
	DialogicUtil.add_file_to_folder(editor_reference.flat_structure, "Timelines",folder, timeline['metadata']['file'])
	build_timelines(timeline['metadata']['file'])
	hide_all_editors()
	#rename_selected()


# creates a new character and opens it
# it will be added to the selected folder (if it's a character folder) or the Character root folder
# {category:Characters, editor:Character Root, name:, path:, step:0}
func new_character():
	var character = editor_reference.get_node("MainPanel/CharacterEditor").create_character()
	var folder = {'category':'Characters', 'editor':'Character Root', 'name':'', 'path':'', 'step':0}
	if get_selected() != null:
		folder = get_selected().get_metadata(0)
	DialogicUtil.add_file_to_folder(editor_reference.flat_structure, "Characters",folder, character['metadata']['file'])
	build_characters(character['metadata']['file'])
	hide_all_editors()
	#rename_selected()

# creates a new theme and opens it
# it will be added to the selected folder (if it's a theme folder) or the Theme root folder
func new_theme():
	var theme_file = editor_reference.get_node("MainPanel/ThemeEditor").create_theme()
	var folder = {'category':'Themes', 'editor':'Theme Root', 'name':'', 'path':'', 'step':0}
	if get_selected() != null:
		folder = get_selected().get_metadata(0)
	DialogicUtil.add_file_to_folder(editor_reference.flat_structure, "Themes",folder, theme_file)
	build_themes(theme_file)
	hide_all_editors()
	#rename_selected()

# creates a new value and opens it
# it will be added to the selected folder (if it's a definition folder) or the Definition root folder
func new_value_definition():
	var definition_id = editor_reference.get_node("MainPanel/ValueEditor").create_value()
	var folder = {'category':'Definitions', 'editor':'Definition Root', 'name':'', 'path':'', 'step':0}
	if get_selected() != null:
		folder = get_selected().get_metadata(0)
	folder['type'] = 0
	DialogicUtil.add_file_to_folder(editor_reference.flat_structure, "Definitions",folder, definition_id)
	build_definitions(definition_id)
	hide_all_editors()
	#rename_selected()

# creates a new glossary entry and opens it
# it will be added to the selected folder (if it's a definition folder) or the Definition root folder
func new_glossary_entry():
	var definition_id = editor_reference.get_node("MainPanel/GlossaryEntryEditor").create_glossary_entry()
	var folder = {'category':'Definitions', 'editor':'Definition Root', 'name':'', 'path':'', 'step':0}
	if get_selected() != null:
		folder = get_selected().get_metadata(0)
	folder['type'] = 1
	DialogicUtil.add_file_to_folder(editor_reference.flat_structure, "Definitions",folder, definition_id)
	build_definitions(definition_id)
	hide_all_editors()
	#rename_selected()
	
func update_definition_entry(text):
	# special funciton needed for name changes to the two definition types
	var current = get_selected().get_metadata(0)

func remove_selected():
	var item = get_selected()
	var folder = get_selected().get_metadata(0)
	if folder['editortype'] == "folder":
		DialogicUtil.remove_folder(editor_reference.flat_structure, folder['category'], folder, false)
	else:
		DialogicUtil.remove_file_from_folder(editor_reference.flat_structure, folder['category'], folder)
	settings_editor.update_data()
	hide_all_editors()
	build_flat_tree_items(folder['category'])


func rename_selected():
	yield(get_tree(), "idle_frame")
	_start_rename()
	edit_selected()
	hide_all_editors()

## *****************************************************************************
##					 		DRAGGING ITEMS
## *****************************************************************************

func can_drop_data(position, data) -> bool:
	if tree.drop_mode_flags == DROP_MODE_DISABLED:
		tree.set_drop_mode_flags(DROP_MODE_ON_ITEM | DROP_MODE_INBETWEEN)
		
	var item = get_item_at_position(position)
	if item == null:
		return false
	# if the data isn't empty and it's a valid DICT
	if data != null and data is Dictionary and data.has('item_type'):
		# if the item is the same category as the original
		if item.get_metadata(0)['category'] == data['category']:
			#if we're moving to the root, no further checks needed
			if item.get_metadata(0)['step'] == 0:
				return true
			# if the folders not moving a root folder into a subfolder of itself
			if not ((data['item_type'] == "folder" and item.get_metadata(0)["editortype"] == "folder") and (data['orig_path'] + data['name']) in item.get_metadata(0)['path']):
				return true
	return false

func drop_data(position, data):
	var item = get_item_at_position(position)
	var drop_section = get_drop_section_at_position(position)
	if not data.has('item_type'):
		return
	# dragging a folder
	if data['item_type'] == 'folder':
		# on a folder
		if 'Root' in item.get_metadata(0)['editor']: 
			DialogicUtil.move_folder_to_folder(editor_reference.flat_structure, item.get_metadata(0)['category'], data, item.get_metadata(0), drop_section)
	# dragging a file
	elif data['item_type'] == 'file':
		# on a folder
		if 'Root' in item.get_metadata(0)['editor']:
			if data.has('file_name'):
				DialogicUtil.move_file_to_folder(editor_reference.flat_structure, item.get_metadata(0)['category'], data, item.get_metadata(0), drop_section)
			elif data.has('resource_id'):
				DialogicUtil.move_file_to_folder(editor_reference.flat_structure, item.get_metadata(0)['category'], data, item.get_metadata(0), drop_section)
				pass # WORK TODO
		# on a file
		else:
			DialogicUtil.move_file_to_folder(editor_reference.flat_structure, item.get_metadata(0)['category'], data, item.get_metadata(0), drop_section)
	dragging_item.queue_free()
	dragging_item = null
	
	build_full_tree()

func get_drag_data(position):
	var item = get_item_at_position(position)
	# if it is a folder and it's not one of the root folders
	if 'Root' in item.get_metadata(0)['editor'] and item.get_parent().get_parent():
		instance_drag_preview(item.get_icon(0), item.get_text(0))
		return {'item_type': 'folder', 'name': item.get_metadata(0)['name'], 'orig_path': get_item_folder(item, ""), 'category': item.get_metadata(0)['category'], 'original_step': item.get_metadata(0)['step']}
	else:
		if item.get_metadata(0).has('file'):
			instance_drag_preview(item.get_icon(0), item.get_text(0))
			return {'item_type': 'file', 'orig_path': item.get_metadata(0)['path'], 'file_name':item.get_metadata(0)['file'], 'category': item.get_metadata(0)['category'], 'name': item.get_metadata(0)['name'], 'original_step': item.get_metadata(0)['step']}
		elif item.get_metadata(0).has('id'):
			instance_drag_preview(item.get_icon(0), item.get_text(0))
			return {'item_type': 'file', 'orig_path': item.get_metadata(0)['path'], 'resource_id':item.get_metadata(0)['id'], 'category': item.get_metadata(0)['category'], 'name': item.get_metadata(0)['name'], 'original_step': item.get_metadata(0)['step']}
	return null

func instance_drag_preview(icon, text):
	dragging_item = drag_preview.instance()
	dragging_item.get_node("Panel").self_modulate = get_color("base_color", "Editor")
	dragging_item.get_node("Panel/HBox/Icon").texture = icon
	dragging_item.get_node("Panel/HBox/Label").text = text
	editor_reference.add_child(dragging_item)

func _process(delta):
	if dragging_item != null:
		if Input.is_mouse_button_pressed(1):
			dragging_item.rect_global_position = get_global_mouse_position()+Vector2(10,10)
		else:
			dragging_item.queue_free()
			dragging_item = null



## *****************************************************************************
##						 ITEM EDITING (RENAMING)
## *****************************************************************************

func _on_renamer_reset_timeout():
	get_selected().set_editable(0, false)


func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.is_pressed() and event.doubleclick:
			_start_rename()


func _start_rename():
	var item = get_selected()
	var metadata = item.get_metadata(0)
	if metadata.has("editable") and metadata["editable"]:
		item_path_before_edit = get_item_path(item)['path']
		item.set_editable(0, true)
		$RenamerReset.start(0.5)


func _on_item_edited():
	var item = get_selected()
	var metadata = item.get_metadata(0)
	if metadata['editor'] == 'Timeline':
		timeline_editor.timeline_name = item.get_text(0)
		DialogicUtil.rename_file(editor_reference.flat_structure, 'Timelines', metadata, item.get_text(0))
		save_current_resource()
		build_timelines(metadata['file'])
	if metadata['editor'] == 'Theme':
		DialogicResources.set_theme_value(metadata['file'], 'settings', 'name', item.get_text(0))
		DialogicUtil.rename_file(editor_reference.flat_structure, 'Themes', metadata, item.get_text(0))
		build_themes(metadata['file'])
	if metadata['editor'] == 'Character':
		character_editor.nodes['name'].text = item.get_text(0)
		DialogicUtil.rename_file(editor_reference.flat_structure, 'Characters', metadata, item.get_text(0))
		save_current_resource()
		build_characters(metadata['file'])
	if metadata['editor'] == 'Value':
		value_editor.nodes['name'].text = item.get_text(0)
		# Not sure why this signal doesn't triggers
		value_editor._on_name_changed(item.get_text(0))
		DialogicUtil.rename_file(editor_reference.flat_structure, 'Definitions', metadata, item.get_text(0))
		save_current_resource()
		build_definitions(metadata['id'])
	if metadata['editor'] == 'GlossaryEntry':
		glossary_entry_editor.nodes['name'].text = item.get_text(0)
		# Not sure why this signal doesn't triggers
		glossary_entry_editor._on_name_changed(item.get_text(0))
		DialogicUtil.rename_file(editor_reference.flat_structure, 'Definitions', metadata, item.get_text(0))
		save_current_resource()
		build_definitions(metadata['id'])

	if "Root" in metadata['editor']:
		if item.get_text(0) == item_path_before_edit.split("/")[-1]:
			return 
		var result = DialogicUtil.rename_folder(editor_reference.flat_structure, metadata['category'], metadata, item.get_text(0))
		if result != OK:
			item.set_text(0, item.get_text(0))
			
		
		build_flat_tree_items(metadata['category'])
		
	hide_all_editors()
			
## *****************************************************************************
##					 		AUTO SAVING
## *****************************************************************************

func _on_autosave_timeout():
	save_current_resource()

func save_current_resource():
	if editor_reference and editor_reference.visible: #Only save if the editor is open
		var item: TreeItem = get_selected()
		var metadata: Dictionary
		if item != null:
			metadata = item.get_metadata(0)
			if metadata['editor'] == 'Timeline':
				timeline_editor.save_timeline()
			if metadata['editor'] == 'Character':
				if character_editor.has_meta('current_color'):
					editor_reference.flat_structure['Characters_Array'][character_editor.get_meta('tree_position')]['value']['color'] = character_editor.get_meta('current_color')
				else:
					character_editor.set_meta('current_color', Color.white)	
				character_editor.save_character()
			if metadata['editor'] == 'Value':
				value_editor.save_definition()
			if metadata['editor'] == 'GlossaryEntry':
				glossary_entry_editor.save_definition()
			# Note: Theme files auto saves on change


## *****************************************************************************
##					 	SEARCHING/FILTERING
## *****************************************************************************


func _on_filter_tree_edit_changed(value):
	filter_tree_term = value
	if not filter_tree_term.empty():
		timelines_tree.collapsed = false
		characters_tree.collapsed = false
		definitions_tree.collapsed = false
		themes_tree.collapsed = false
	else:
		timelines_tree.collapsed = editor_reference.flat_structure['Timelines']['/.']['folded']
		characters_tree.collapsed = editor_reference.flat_structure['Characters']['/.']['folded']
		definitions_tree.collapsed = editor_reference.flat_structure['Definitions']['/.']['folded']
		themes_tree.collapsed = editor_reference.flat_structure['Themes']['/.']['folded']
	
	build_full_tree()
	
	# This was merged, not sure if it is properly placed
	build_documentation()


## *****************************************************************************
##					 	SELECTING AN ITEM
## *****************************************************************************

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


func select_documentation_item(docs_page_path):
	if not $DocsTreeHelper.search_and_select_docs(documentation_tree, docs_page_path):
		hide_all_editors()
