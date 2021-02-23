tool
extends Tree

var editor_reference
onready var timeline_editor = get_node('../TimelineEditor')
onready var tree = self
var timeline_icon = load("res://addons/dialogic/Images/timeline.svg")
var character_icon = load("res://addons/dialogic/Images/character.svg")
var timelines_tree
var characters_tree

func _ready():
	allow_rmb_select = true
	var root = tree.create_item()
	tree.set_hide_root(true)
	
	# Creating the parents
	timelines_tree = tree.create_item(root)
	timelines_tree.set_text(0, "Timelines")
	characters_tree = tree.create_item(root)
	characters_tree.set_text(0, "Characters")
	
	
	connect('item_selected', self, '_on_item_selected')
	connect('item_rmb_selected', self, '_on_item_rmb_selected')
	
	#var subchild1 = tree.create_item(timelines_tree)
	#subchild1.set_text(0, "Subchild1")
	
	# Adding timelines
	for c in DialogicUtil.get_timeline_list():
		add_timeline(c)
	
	# Adding characters
	for c in DialogicUtil.get_character_list():
		var item = tree.create_item(characters_tree)
		item.set_icon(0, character_icon)
		item.set_text(0, c['name'])
		c['editor'] = 'EditorCharacter'
		item.set_metadata(0, c)
		#item.set_editable(0, true)
		item.set_icon_modulate(0, c['color'])
	
	# Glossary
	# TODO

func _on_item_selected():
	var item = get_selected().get_metadata(0)
	if item['editor'] == 'EditorTimeline':
		timeline_editor.save_timeline()
		timeline_editor.clear_timeline()
		timeline_editor.load_timeline(DialogicUtil.get_path('TIMELINE_DIR', item['file']))


func _on_item_rmb_selected(position):
	var item = get_selected().get_metadata(0)
	if item['editor'] == 'EditorTimeline':
		editor_reference.get_node('TimelinePopupMenu').rect_position = get_viewport().get_mouse_position()
		editor_reference.get_node('TimelinePopupMenu').popup()
		#timeline_name = dialog_list.get_item_text(index)


func add_timeline(timeline, select = false):
	var item = tree.create_item(timelines_tree)
	item.set_icon(0, timeline_icon)
	if timeline.has('name'):
		item.set_text(0, timeline['name'])
	else:
		item.set_text(0, timeline['file'])
	timeline['editor'] = 'EditorTimeline'
	item.set_metadata(0, timeline)
	#item.set_editable(0, true)
	#dialog_list.set_item_metadata(index, {'file': c['file'], 'index': index})
	if select:
		item.select(0)


func refresh_timeline_list():
	print('update timeline list')
