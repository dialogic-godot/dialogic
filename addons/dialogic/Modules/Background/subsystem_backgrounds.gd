extends DialogicSubsystem

## Subsystem for managing backgrounds.

signal background_changed(info:Dictionary)

var _tween: Tween
var _tween_callbacks: Array[Callable]

var default_background_scene: PackedScene = load(get_script().resource_path.get_base_dir().path_join('default_background.tscn'))

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
	var background_holder: DialogicNode_BackgroundHolder = get_tree().get_first_node_in_group('dialogic_background_holders')
	if background_holder == null:
		return

	var info := {'scene':scene, 'argument':argument, 'fade_time':fade_time, 'same_scene':false}
	var bg_set := false

	# First try just updating the existing scene.
	if scene == dialogic.current_state_info.get('background_scene', ''):
		for old_bg in background_holder.get_children():
			if !old_bg.has_meta('node') or not old_bg.get_meta('node') is DialogicBackground:
				continue

			var prev_bg_node: DialogicBackground = old_bg.get_meta('node')
			if prev_bg_node._should_do_background_update(argument):
				prev_bg_node._update_background(argument, fade_time)
				bg_set = true
				info['same_scene'] = true

	# If that didn't work, add a new scene, then cross-fade
	if !bg_set:
		var material: Material = background_holder.material
		# make sure material is clean and ready to go
		material.set_shader_parameter("progress", 0)
		# swap the next background into previous, as that is now the older frame
		material.set_shader_parameter("previous_background", material.get_shader_parameter("next_background"))
		material.set_shader_parameter("next_background", null)

		if _tween:
			_tween.kill()

		_tween = get_tree().create_tween()

		# could be implemented as passed by the event
		#material.set_shader_parameter("whipe_texture", whipe_texture)	# the direction the whipe takes from black to white
		#material.set_shader_parameter("feather", feather)				# the trailing smear left behind when the whipe happens

		_tween.tween_method(func (progress: float):
			material.set_shader_parameter("progress", progress)
		, 0.0, 1.0, fade_time)

		## remove previous backgrounds
		for old_bg in background_holder.get_children():
			if old_bg is SubViewportContainer:
				old_bg.get_meta('node')._custom_fade_out(fade_time)
				_tween.chain().tween_callback(old_bg.queue_free)

		var new_node: SubViewportContainer
		if scene.ends_with('.tscn') and ResourceLoader.exists(scene):
			new_node = add_background_node(load(scene), background_holder)
			if not new_node.get_meta('node') is DialogicBackground:
				printerr("[Dialogic] Given background scene was not of type DialogicBackground!")
		elif argument:
			new_node = add_background_node(default_background_scene, background_holder)
		else:
			new_node = null

		if new_node:
			new_node.get_meta('node')._update_background(argument, fade_time)
			new_node.get_meta('node')._custom_fade_in(fade_time)
			material.set_shader_parameter("next_background", new_node.get_child(0).get_texture())

	dialogic.current_state_info['background_scene'] = scene
	dialogic.current_state_info['background_argument'] = argument
	background_changed.emit(info)


func add_background_node(scene:PackedScene, parent:DialogicNode_BackgroundHolder) -> SubViewportContainer:
	var v_con := SubViewportContainer.new()
	var viewport := SubViewport.new()
	var b_scene := scene.instantiate()

	parent.add_child(v_con)
	v_con.visible = false
	v_con.stretch = true
	v_con.size = parent.size
	v_con.set_anchors_preset(Control.PRESET_FULL_RECT)

	v_con.add_child(viewport)
	viewport.transparent_bg = true
	viewport.disable_3d = true

	viewport.add_child(b_scene)
	b_scene.viewport = viewport
	b_scene.viewport_container = v_con

	v_con.set_meta('node', b_scene)

	return v_con


func has_background() -> bool:
	return !dialogic.current_state_info['background_scene'].is_empty() or !dialogic.current_state_info['background_argument'].is_empty()

