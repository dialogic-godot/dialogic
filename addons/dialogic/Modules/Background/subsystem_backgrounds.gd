extends DialogicSubsystem

## Subsystem for managing backgrounds.

signal background_changed(info:Dictionary)

var _tween: Tween
var _tween_callbacks: Array[Callable]

var default_background_scene: PackedScene = load(get_script().resource_path.get_base_dir().path_join('DefaultBackgroundScene/default_background.tscn'))
var default_transition: String = get_script().resource_path.get_base_dir().path_join("Transitions/Defaults/simple_fade.gd")

####################################################################################################
##					STATE
####################################################################################################

func clear_game_state(clear_flag:=DialogicGameHandler.ClearFlags.FULL_CLEAR):
	update_background()


func load_game_state(load_flag:=LoadFlags.FULL_LOAD):
	update_background(dialogic.current_state_info.get('background_scene', ''), dialogic.current_state_info.get('background_argument', ''), 0.0, default_transition, true)


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
func update_background(scene:String = '', argument:String = '', fade_time:float = 0.0, transition_path:=default_transition, force:bool = false) -> void:
	var background_holder: DialogicNode_BackgroundHolder
	if dialogic.has_subsystem('Styles'):
		background_holder = dialogic.Styles.get_first_node_in_layout('dialogic_background_holders')
	else:
		background_holder = get_tree().get_first_node_in_group('dialogic_background_holders')
	if background_holder == null:
		return

	var info := {'scene':scene, 'argument':argument, 'fade_time':fade_time, 'same_scene':false}

	var bg_set := false

	# First try just updating the existing scene.
	if scene == dialogic.current_state_info.get('background_scene', ''):

		if not force and argument == dialogic.current_state_info.get('background_argument', ''):
			return

		for old_bg in background_holder.get_children():
			if !old_bg.has_meta('node') or not old_bg.get_meta('node') is DialogicBackground:
				continue

			var prev_bg_node: DialogicBackground = old_bg.get_meta('node')
			if prev_bg_node._should_do_background_update(argument):
				prev_bg_node._update_background(argument, fade_time)
				bg_set = true
				info['same_scene'] = true

	dialogic.current_state_info['background_scene'] = scene
	dialogic.current_state_info['background_argument'] = argument

	if bg_set:
		background_changed.emit(info)
		return

	var old_viewport: SubViewportContainer = null
	if background_holder.has_meta('current_viewport'):
		old_viewport = background_holder.get_meta('current_viewport', null)

	var new_viewport: SubViewportContainer
	if scene.ends_with('.tscn') and ResourceLoader.exists(scene):
		new_viewport = add_background_node(load(scene), background_holder)
	elif argument:
		new_viewport = add_background_node(default_background_scene, background_holder)
	else:
		new_viewport = null

	var trans_script :Script = load(DialogicResourceUtil.guess_special_resource("BackgroundTransition", transition_path, default_transition))
	var trans_node := Node.new()
	trans_node.set_script(trans_script)
	trans_node = (trans_node as DialogicBackgroundTransition)
	trans_node.bg_holder = background_holder
	trans_node.time = fade_time

	if old_viewport:
		trans_node.prev_scene = old_viewport.get_meta('node', null)
		trans_node.prev_texture = old_viewport.get_child(0).get_texture()
		old_viewport.get_meta('node')._custom_fade_out(fade_time)
		trans_node.transition_finished.connect(old_viewport.queue_free)
	if new_viewport:
		trans_node.next_scene = new_viewport.get_meta('node', null)
		trans_node.next_texture = new_viewport.get_child(0).get_texture()
		new_viewport.get_meta('node')._update_background(argument, fade_time)
		new_viewport.get_meta('node')._custom_fade_in(fade_time)
	else:
		background_holder.remove_meta('current_viewport')

	add_child(trans_node)
	trans_node._fade()
	trans_node.transition_finished.connect(trans_node.queue_free)

	background_changed.emit(info)


func add_background_node(scene:PackedScene, parent:DialogicNode_BackgroundHolder) -> SubViewportContainer:
	var v_con := SubViewportContainer.new()
	var viewport := SubViewport.new()
	var b_scene := scene.instantiate()
	if not b_scene is DialogicBackground:
		printerr("[Dialogic] Given background scene was not of type DialogicBackground! Make sure the scene has a script that extends DialogicBackground.")
		v_con.queue_free()
		viewport.queue_free()
		b_scene.queue_free()
		return null

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

	parent.set_meta('current_viewport', v_con)
	v_con.set_meta('node', b_scene)

	return v_con


func has_background() -> bool:
	return !dialogic.current_state_info.get('background_scene', '').is_empty() or !dialogic.current_state_info.get('background_argument','').is_empty()


