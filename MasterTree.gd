extends Tree


func _ready():
	var tree = self
	var root = tree.create_item()
	tree.set_hide_root(true)
	
	# Creating the parents
	var timelines_tree = tree.create_item(root)
	timelines_tree.set_text(0, "Timelines")
	var characters_tree = tree.create_item(root)
	characters_tree.set_text(0, "Characters")
	
	
	#var subchild1 = tree.create_item(timelines_tree)
	#subchild1.set_text(0, "Subchild1")
	
	var timeline_icon = load("res://addons/dialogic/Images/timeline.svg")
	var character_icon = load("res://addons/dialogic/Images/character.svg")
	
	# Adding timelines
	for c in DialogicUtil.get_timeline_list():
		var item = tree.create_item(timelines_tree)
		item.set_icon(0, timeline_icon)
		item.set_text(0, c['name'])
		#dialog_list.set_item_metadata(index, {'file': c['file'], 'index': index})
	
	# Adding characters
	for c in DialogicUtil.get_character_list():
		var item = tree.create_item(characters_tree)
		item.set_icon(0, character_icon)
		item.set_text(0, c['name'])
		item.set_icon_modulate(0, c['color'])
	
	# Glossary
	# TODO
