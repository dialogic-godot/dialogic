extends DialogicSubsystem

## Subsystem for managing backgrounds. 

signal background_changed(info:Dictionary)


var default_background_scene :PackedScene = load(get_script().resource_path.get_base_dir().path_join('default_background.tscn'))
####################################################################################################
##					STATE
####################################################################################################

func clear_game_state(clear_flag:=Dialogic.ClearFlags.FullClear):
	update_background()


func load_game_state():
	update_background(dialogic.current_state_info.get('background_scene', ''), dialogic.current_state_info.get('background_argument', ''))


####################################################################################################
##					MAIN METHODS
####################################################################################################

## Method that adds a given scene as child of the DialogicNode_BackgroundHolder. 
## It will call [_update_background()] on that scene with the given argument [argument].
## It will call [_fade_in()] on that scene with the given fade time.
## Will call fade_out on previous backgrounds scene.
##
## If the scene is the same as the last background you can bypass another instantiating 
## and use the same scene.
## To do so implement [_should_do_background_update()] on the custom background scene.
## Then  [_update_background()] will be called directly on that previous scene.
func update_background(scene:String = '', argument:String = '', fade_time:float = 0.0) -> void:
	var info := {'scene':scene, 'argument':argument, 'fade_time':fade_time, 'same_scene':false}
	for node in get_tree().get_nodes_in_group('dialogic_background_holders'):
		if node.visible:
			var bg_set: bool = false
			if scene == dialogic.current_state_info['background_scene']:
				for old_bg in node.get_children():
					if old_bg.has_method("_should_do_background_update") and old_bg._should_do_background_update(argument):
						if old_bg.has_method('_update_background'):
							old_bg._update_background(argument, fade_time)
							bg_set = true
							info['same_scene'] = true
			if !bg_set:
				# remove previous backgrounds
				for old_bg in node.get_children():
					
					if !old_bg._fade_out(fade_time) and "modulate" in old_bg:
						var tween := old_bg.create_tween()
						tween.tween_property(old_bg, "modulate", Color.TRANSPARENT, fade_time)
						tween.tween_callback(old_bg.queue_free)
					else:
						old_bg.queue_free()
				
				var new_node:Node
				if scene.ends_with('.tscn'):
					new_node = load(scene).instantiate()
				elif argument:
					new_node = default_background_scene.instantiate() 
				else:
					new_node = null
				
				if new_node:
					node.add_child(new_node)
					
					if new_node.has_method('_update_background'):
						new_node._update_background(argument, fade_time)
					
					if !new_node._fade_in(fade_time) and "modulate" in new_node:
						new_node.modulate = Color.TRANSPARENT
						var tween := new_node.create_tween()
						tween.tween_property(new_node, "modulate", Color.WHITE, fade_time)
	
	dialogic.current_state_info['background_scene'] = scene
	dialogic.current_state_info['background_argument'] = argument
	background_changed.emit(info)
