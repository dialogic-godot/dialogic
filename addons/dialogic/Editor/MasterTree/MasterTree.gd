tool
extends Tree

var editor_reference
onready var timeline_editor = get_node('../TimelineEditor')

func _ready():
	var tree = self
	var root = tree.create_item()
	tree.set_hide_root(true)
	
	
	# Connecting signals
	
	
	# Creating the parents
	var timelines_tree = tree.create_item(root)
	timelines_tree.set_text(0, "Timelines")
	var characters_tree = tree.create_item(root)
	characters_tree.set_text(0, "Characters")
	
	
	connect('item_selected', self, '_on_item_selected')
	
	#var subchild1 = tree.create_item(timelines_tree)
	#subchild1.set_text(0, "Subchild1")
	
	var timeline_icon = load("res://addons/dialogic/Images/timeline.svg")
	var character_icon = load("res://addons/dialogic/Images/character.svg")
	
	# Adding timelines
	for c in DialogicUtil.get_timeline_list():
		var item = tree.create_item(timelines_tree)
		item.set_icon(0, timeline_icon)
		item.set_text(0, c['name'])
		c['editor'] = 'EditorTimeline'
		item.set_metadata(0, c)
		#item.set_editable(0, true)
		#dialog_list.set_item_metadata(index, {'file': c['file'], 'index': index})
	
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
	print(item)

	if item['editor'] == 'EditorTimeline':
		#editor_reference.manual_save()
		timeline_editor.clear_timeline()
		timeline_editor.load_timeline(DialogicUtil.get_path('TIMELINE_DIR', item['file']))


func refresh_timeline_list():
	print('update timeline list')
