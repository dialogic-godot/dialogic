extends DialogicSubsystem


####################################################################################################
##					STATE
####################################################################################################

func clear_game_state():
	update_background()

func load_game_state():
	update_background(dialogic.current_state_info.get('background', ''))

####################################################################################################
##					MAIN METHODS
####################################################################################################
func update_background(path:String = '') -> void:
	dialogic.current_state_info['background'] = path
	for node in get_tree().get_nodes_in_group('dialogic_bg_image'):
		if node.is_visible_in_tree():
			for child in node.get_children():
				child.queue_free()
			node.texture = null
			if path.ends_with('.tscn'):
				node.add_child(load(path).instanciate())
			elif not path.empty():
				node.texture = load(path)
