extends DialogicSubsystem

## Subsystem for managing backgrounds. 

signal background_changed(info:Dictionary)


var default_background_scene :PackedScene = load(get_script().resource_path.get_base_dir().path_join('default_background.tscn'))
####################################################################################################
##					STATE
####################################################################################################

func clear_game_state(clear_flag:=Dialogic.ClearFlags.FULL_CLEAR):
	update_background()


func load_game_state(load_flag:=LoadFlags.FULL_LOAD):
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
					if old_bg is DialogicBackground and old_bg._should_do_background_update(argument):
						old_bg._update_background(argument, fade_time)
						bg_set = true
						info['same_scene'] = true
			if !bg_set:
				# maybe should look into making this a unique instance if multiple background holders are expected
				var mat = preload("res://addons/dialogic/Modules/Background/default_background_transition.tres") as ShaderMaterial
				var transition_overlay := ColorRect.new()
				var tran_tween := get_tree().create_tween()
				
				# make sure material is clean and ready to go
				mat.set_shader_parameter("progress", 0)
				mat.set_shader_parameter("previousBackground", null)
				mat.set_shader_parameter("nextBackground", null)
				
				# could be implemented as passed by the event
				#mat.set_shader_parameter("whipeTexture", whipe_texture)	# the direction the whipe takes from black to white
				#mat.set_shader_parameter("feather", feather)				# the trailing smear left behind when the whipe happens
				
				tran_tween.tween_method(func (progress: float):
					mat.set_shader_parameter("progress", progress)
				, 0.0, 1.0, fade_time)
				
				# set up transition overlay
				transition_overlay.anchor_right = 1
				transition_overlay.anchor_bottom = 1
				# TODO: maybe make this more modular
				transition_overlay.material = mat
				
				tran_tween.tween_callback(_free_bg_node.bind(transition_overlay))
				
				
				# remove previous backgrounds
				for old_bg in node.get_children():
					if old_bg is DialogicBackground: 
						old_bg._fade_out(fade_time) # left in as it can be used to tell the bg that it faded out
						mat.set_shader_parameter("previousBackground", old_bg._get_background_texture())
						
					# remove the old background after the fade is over
					tran_tween.tween_callback(_free_bg_node.bind(old_bg))
					
					#if !old_bg._fade_out(fade_time) and "modulate" in old_bg:
					#	var tween := old_bg.create_tween()
					#	tween.tween_property(old_bg, "modulate", Color.TRANSPARENT, fade_time)
					#	tween.tween_callback(old_bg.queue_free)
					#else:
					#	old_bg.queue_free()
				
				var new_node:Node
				if scene.ends_with('.tscn'):
					new_node = load(scene).instantiate()
					if !new_node is DialogicBackground:
						printerr("[Dialogic] Tried using custom backgrounds that doesn't extend DialogicBackground class!")
						new_node.queue_free()
						new_node  = null
				elif argument:
					new_node = default_background_scene.instantiate() as DialogicBackground
				else:
					new_node = null
				
				if new_node:
					node.add_child(new_node)
					
					new_node._update_background(argument, fade_time)
					new_node._fade_in(fade_time) # left in as it can be used to tell the bg that it faded in
					
					mat.set_shader_parameter("nextBackground", new_node._get_background_texture())
					
					
					
					#if new_node.has_method('_update_background'):
					#	new_node._update_background(argument, fade_time)
					
					#if !new_node._fade_in(fade_time) and "modulate" in new_node:
					#	new_node.modulate = Color.TRANSPARENT
					#	var tween := new_node.create_tween()
					#	tween.tween_property(new_node, "modulate", Color.WHITE, fade_time)
				
				node.add_child(transition_overlay)
	
	dialogic.current_state_info['background_scene'] = scene
	dialogic.current_state_info['background_argument'] = argument
	background_changed.emit(info)

func _free_bg_node(node) -> void:
	if node and is_instance_valid(node) and !node.is_queued_for_deletion():
		node.queue_free()

func has_background() -> bool:
	return !dialogic.current_state_info['background_scene'].is_empty() or !dialogic.current_state_info['background_argument'].is_empty()

