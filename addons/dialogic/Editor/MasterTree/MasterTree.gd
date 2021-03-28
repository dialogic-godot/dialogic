tool
extends Tree

onready var editor_reference = get_node('../..')
onready var timeline_editor = get_node('../TimelineEditor')
onready var character_editor = get_node('../CharacterEditor')
onready var definition_editor = get_node('../DefinitionEditor')
onready var settings_editor = get_node('../SettingsEditor')
onready var theme_editor = get_node('../ThemeEditor')
onready var empty_editor = get_node('../Empty')

onready var tree = self
var timeline_icon = load("res://addons/dialogic/Images/timeline.svg")
var character_icon = load("res://addons/dialogic/Images/character.svg")
var theme_icon = load("res://addons/dialogic/Images/Resources/theme.svg")
var definition_icon = load("res://addons/dialogic/Images/Resources/definition.svg")
var glossary_icon = load("res://addons/dialogic/Images/Resources/glossary.svg")
var timelines_tree
var characters_tree
var definitions_tree
var themes_tree
var settings_tree

signal editor_selected(selected)

func _ready():
	allow_rmb_select = true
	var root = tree.create_item()
	tree.set_hide_root(true)
	
	# Creating the parents
	timelines_tree = tree.create_item(root)
	timelines_tree.set_selectable(0, false)
	timelines_tree.set_text(0, "Timelines")
	#timelines_tree.set_icon(0, get_icon("Folder", "EditorIcons"))
	
	characters_tree = tree.create_item(root)
	characters_tree.set_selectable(0, false)
	characters_tree.set_text(0, "Characters")
	#characters_tree.set_icon(0, get_icon("Folder", "EditorIcons"))

	definitions_tree = tree.create_item(root)
	definitions_tree.set_selectable(0, false)
	definitions_tree.set_text(0, "Definitions")
	#definitions_tree.set_icon(0, get_icon("Folder", "EditorIcons"))
	
	themes_tree = tree.create_item(root)
	themes_tree.set_selectable(0, false)
	themes_tree.set_text(0, "Themes")
	#themes_tree.set_icon(0, get_icon("Folder", "EditorIcons"))
	
	settings_tree = tree.create_item(root)
	settings_tree.set_selectable(0, true)
	settings_tree.set_text(0, "Settings")
	settings_tree.set_icon(0, get_icon("GDScript", "EditorIcons"))
	settings_tree.set_metadata(0, {'editor': 'Settings'})

	
	connect('item_selected', self, '_on_item_selected')
	connect('item_rmb_selected', self, '_on_item_rmb_selected')
	connect('gui_input', self, '_on_gui_input')
	connect('item_edited', self, '_on_item_edited')
	$RenamerReset.connect("timeout", self, '_on_renamer_reset_timeout')
	
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
	for t in DialogicUtil.get_sorted_timeline_list():
		_add_timeline(t, not selected_item.empty() and t['file'] == selected_item)


func _add_timeline(timeline, select = false):
	var item = tree.create_item(timelines_tree)
	item.set_icon(0, timeline_icon)
	if timeline.has('name'):
		item.set_text(0, timeline['name'])
	else:
		item.set_text(0, timeline['file'])
	timeline['editor'] = 'Timeline'
	item.set_metadata(0, timeline)
	if not get_constant("dark_theme", "Editor"):
		item.set_icon_modulate(0, get_color("property_color", "Editor"))
	#item.set_editable(0, true)
	if select: # Auto selecting
		item.select(0)


func build_themes(selected_item: String=''):
	_clear_tree_children(themes_tree)
	for t in DialogicUtil.get_sorted_theme_list():
		_add_theme(t, not selected_item.empty() and t['file'] == selected_item)


func _add_theme(theme_item, select = false):
	var item = tree.create_item(themes_tree)
	item.set_icon(0, theme_icon)
	item.set_text(0, theme_item['name'])
	theme_item['editor'] = 'Theme'
	item.set_metadata(0, theme_item)
	if not get_constant("dark_theme", "Editor"):
		item.set_icon_modulate(0, get_color("property_color", "Editor"))
	if select: # Auto selecting
		item.select(0)


func build_characters(selected_item: String=''):
	_clear_tree_children(characters_tree)
	for t in DialogicUtil.get_sorted_character_list():
		_add_character(t, not selected_item.empty() and t['file'] == selected_item)


func _add_character(character, select = false):
	var item = tree.create_item(characters_tree)
	item.set_icon(0, character_icon)
	if character.has('name'):
		item.set_text(0, character['name'])
	else:
		item.set_text(0, character['file'])
	character['editor'] = 'Character'
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
		_add_definition(t, not selected_item.empty() and t['id'] == selected_item)


func _add_definition(definition, select = false):
	var item = tree.create_item(definitions_tree)
	item.set_text(0, definition['name'])
	item.set_icon(0, definition_icon)
	if definition['type'] == 1:
		item.set_icon(0, glossary_icon)
	definition['editor'] = 'Definition'
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
	if metadata['editor'] == 'Character':
		if not character_editor.is_selected(metadata['file']):
			character_editor.load_character(metadata['file'])
		show_character_editor()
	if metadata['editor'] == 'Definition':
		if not definition_editor.is_selected(metadata['id']):
			definition_editor.visible = true
			definition_editor.load_definition(metadata['id'])
		show_definition_editor()
	if metadata['editor'] == 'Theme':
		theme_editor.load_theme(metadata['file'])
		show_theme_editor()
	if metadata['editor'] == 'Settings':
		settings_editor.update_data()
		show_settings_editor()


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


func _on_item_rmb_selected(position):
	var item = get_selected().get_metadata(0)
	if item['editor'] == 'Timeline':
		editor_reference.get_node('TimelinePopupMenu').rect_position = get_viewport().get_mouse_position()
		editor_reference.get_node('TimelinePopupMenu').popup()
	if item['editor'] == 'Character':
		editor_reference.get_node("CharacterPopupMenu").rect_position = get_viewport().get_mouse_position()
		editor_reference.get_node("CharacterPopupMenu").popup()
	if item['editor'] == 'Theme':
		editor_reference.get_node("ThemePopupMenu").rect_position = get_viewport().get_mouse_position()
		editor_reference.get_node("ThemePopupMenu").popup()
	if item['editor'] == 'Definition':
		editor_reference.get_node("DefinitionPopupMenu").rect_position = get_viewport().get_mouse_position()
		editor_reference.get_node("DefinitionPopupMenu").popup()


func remove_selected():
	var item = get_selected()
	item.free()
	timelines_tree.select(0)
	settings_editor.update_data()


func refresh_timeline_list():
	print('update timeline list')


func _on_renamer_reset_timeout():
	get_selected().set_editable(0, false)


func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.is_pressed() and event.doubleclick:
			var item = get_selected()
			var metadata = item.get_metadata(0)
			item.set_editable(0, true)
			$RenamerReset.start(0.5)


func _on_item_edited():
	print('edited')
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


func _on_autosave_timeout():
	save_current_resource()


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
