tool
extends Tree

var editor_reference
onready var timeline_editor = get_node('../TimelineEditor')
onready var character_editor = get_node('../CharacterEditor')
onready var glossary_editor = get_node('../GlossaryEditor')
onready var theme_editor = get_node('../ThemeEditor')
onready var empty_editor = get_node('../Empty')

onready var tree = self
var timeline_icon = load("res://addons/dialogic/Images/timeline.svg")
var character_icon = load("res://addons/dialogic/Images/character.svg")
var timelines_tree
var characters_tree
var glossary_tree
var themes_tree

func _ready():
	allow_rmb_select = true
	var root = tree.create_item()
	tree.set_hide_root(true)
	
	# Creating the parents
	timelines_tree = tree.create_item(root)
	timelines_tree.set_selectable(0, false)
	timelines_tree.set_text(0, "Timelines")

	
	characters_tree = tree.create_item(root)
	characters_tree.set_selectable(0, false)
	characters_tree.set_text(0, "Characters")

	glossary_tree = tree.create_item(root)
	glossary_tree.set_selectable(0, false)
	glossary_tree.set_text(0, "Glossary")

	themes_tree = tree.create_item(root)
	themes_tree.set_selectable(0, false)
	themes_tree.set_text(0, "Themes")

	
	connect('item_selected', self, '_on_item_selected')
	connect('item_rmb_selected', self, '_on_item_rmb_selected')
	connect('gui_input', self, '_on_gui_input')
	connect('item_edited', self, '_on_item_edited')
	$RenamerReset.connect("timeout", self, '_on_renamer_reset_timeout')
	
	#var subchild1 = tree.create_item(timelines_tree)
	#subchild1.set_text(0, "Subchild1")
	
	# Adding timelines
	for c in DialogicUtil.get_timeline_list():
		add_timeline(c)
	
	# Adding characters
	for c in DialogicUtil.get_character_list():
		add_character(c)
	
	var glossary = DialogicUtil.load_glossary()
	for c in glossary:
		add_glossary(glossary[c])
	# Glossary
	# TODO
	
	# Default empty screen.
	hide_all_editors(true) 
	
	# AutoSave timer
	$AutoSave.connect("timeout", self, '_on_autosave_timeout')
	$AutoSave.start(1)


func add_timeline(timeline, select = false):
	var item = tree.create_item(timelines_tree)
	item.set_icon(0, timeline_icon)
	if timeline.has('name'):
		item.set_text(0, timeline['name'])
	else:
		item.set_text(0, timeline['file'])
	timeline['editor'] = 'Timeline'
	item.set_metadata(0, timeline)
	#item.set_editable(0, true)
	if select: # Auto selecting
		item.select(0)


func add_character(character, select = false):
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


func add_glossary(glossary, select = false):
	print(glossary)
	var item = tree.create_item(glossary_tree)
	if glossary['type'] == DialogicUtil.GLOSSARY_STRING:
		item.set_icon(0, get_icon("String", "EditorIcons"))
	if glossary['type'] == DialogicUtil.GLOSSARY_EXTRA:
		item.set_icon(0, get_icon("ScriptCreateDialog", "EditorIcons"))
	if glossary['type'] == DialogicUtil.GLOSSARY_NUMBER:
		item.set_icon(0, get_icon("int", "EditorIcons"))
	#item.set_icon(0, character_icon)
	if glossary['type'] == DialogicUtil.GLOSSARY_STRING:
		item.set_text(0, glossary['name'] + ' = ' + glossary['string'])
	else:
		item.set_text(0, glossary['name'])
	glossary['editor'] = 'Glossary'
	item.set_metadata(0, glossary)

	#item.set_icon_modulate(0, character['color'])
	if select: # Auto selecting
		item.select(0)


func _on_item_selected():
	# Selecting and opening the proper editor
	var item = get_selected()
	var metadata = item.get_metadata(0)
	hide_all_editors()
	if metadata['editor'] == 'Timeline':
		timeline_editor.visible = true
		timeline_editor.load_timeline(DialogicUtil.get_path('TIMELINE_DIR', metadata['file']))
	if metadata['editor'] == 'Character':
		character_editor.visible = true
		character_editor.load_character(DialogicUtil.get_path('CHAR_DIR', metadata['file']))
	if metadata['editor'] == 'Glossary':
		glossary_editor.visible = true


func hide_all_editors(show_empty = false):
	character_editor.visible = false
	timeline_editor.visible = false
	glossary_editor.visible = false
	theme_editor.visible = false
	empty_editor.visible = false
	if show_empty:
		empty_editor.visible = true


func _on_item_rmb_selected(position):
	var item = get_selected().get_metadata(0)
	if item['editor'] == 'Timeline':
		editor_reference.get_node('TimelinePopupMenu').rect_position = get_viewport().get_mouse_position()
		editor_reference.get_node('TimelinePopupMenu').popup()
	if item['editor'] == 'Character':
		editor_reference.get_node("CharacterPopupMenu").rect_position = get_viewport().get_mouse_position()
		editor_reference.get_node("CharacterPopupMenu").popup()


func remove_selected():
	var item = get_selected()
	item.free()
	timelines_tree.select(0)


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
	var item = get_selected()
	var metadata = item.get_metadata(0)
	if metadata['editor'] == 'Timeline':
		timeline_editor.timeline_name = item.get_text(0)


func _on_autosave_timeout():
	#print('Autosaving')
	save_current_resource()


func save_current_resource():
	var item: TreeItem = get_selected()
	var metadata: Dictionary
	if item != null:
		metadata = item.get_metadata(0)
		if metadata['editor'] == 'Timeline':
			timeline_editor.save_timeline()
		if metadata['editor'] == 'Character':
			character_editor.save_character()
		if metadata['editor'] == 'Glossary':
			print('Save Glossary')
