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
			
			# remove previous backgrounds
			for old_bg in node.get_children():
				if old_bg.has_method('_fade_out'):
					old_bg._fade_out(fade_time)
				elif "modulate" in old_bg:
					var tween = old_bg.create_tween()
					tween.tween_property(old_bg, "modulate", Color.TRANSPARENT, fade_time)
					tween.tween_callback(old_bg.queue_free)
				else:
					old_bg.queue_free()
			
			var new_node
			if path.ends_with('.tscn'):
				new_node = load(path).instantiate()
			elif File.file_exists(path):
				new_node = node.duplicate()
				new_node.texture = load(path)
			else:
				new_node = null
			
			if new_node:
				node.add_child(new_node)
				
				if new_node.has_method('_fade_in'):
					new_node._fade_in(fade_time)
					
				elif "modulate" in new_node:
					new_node.modulate = Color.TRANSPARENT
					var tween = new_node.create_tween()
					tween.tween_property(new_node, "modulate", Color.WHITE, fade_time)
