tool
extends Tree

var editor_reference
onready var timeline_editor = get_node('../TimelineEditor')
onready var character_editor = get_node('../CharacterEditor')
onready var glossary_editor = get_node('../GlossaryEditor')
onready var theme_editor = get_node('../ThemeEditor')

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
	var item = get_selected().get_metadata(0)
	character_editor.visible = false
	timeline_editor.visible = false
	glossary_editor.visible = false
	theme_editor.visible = false
	if item['editor'] == 'Timeline':
		timeline_editor.visible = true
		timeline_editor.save_timeline()
		timeline_editor.load_timeline(DialogicUtil.get_path('TIMELINE_DIR', item['file']))
	if item['editor'] == 'Character':
		character_editor.visible = true
		character_editor.load_character(DialogicUtil.get_path('CHAR_DIR', item['file']))
	if item['editor'] == 'Glossary':
		glossary_editor.visible = true


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
