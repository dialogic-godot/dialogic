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
func update_background(path:String = '', fade_time:float = 0.0) -> void:
	dialogic.current_state_info['background'] = path
	for node in get_tree().get_nodes_in_group('dialogic_bg_image'):
		if node.is_visible_in_tree():
			for child in node.get_children():
				child.queue_free()
				
			# Custom scene's will need to support their own fades
			# We should probably make a signal here to send into them with the data if they want to use it
			if path.ends_with('.tscn'):
				node.add_child(load(path).instantiate())
			
			elif fade_time > 0: 
				node.add_child(node.duplicate())
				node.texture = load(path)
				for child in node.get_children():
					var tween = child.create_tween()
					tween.tween_property(child, "modulate", Color.TRANSPARENT, fade_time)
					tween.tween_callback(child.queue_free)
				
			else:	
				node.texture = null
				if not path.is_empty():
					node.texture = load(path)
					

