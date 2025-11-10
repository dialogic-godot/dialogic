class_name DialogicBackgroundTransition
extends Node

## Helper
var this_folder: String = get_script().resource_path.get_base_dir()


## Set before _fade() is called, will be the root node of the previous bg scene.
var prev_scene: Node
## Set before _fade() is called, will be the viewport texture of the previous bg scene.
var prev_texture: ViewportTexture

## Set before _fade() is called, will be the root node of the upcoming bg scene.
var next_scene: Node
## Set before _fade() is called, will be the viewport texture of the upcoming bg scene.
var next_texture: ViewportTexture

## Set before _fade() is called, will be the requested time for the fade
var time: float

## Set before _fade() is called, will be the background holder (TextureRect)
var bg_holder: DialogicNode_BackgroundHolder


@warning_ignore("unused_signal") # Used by scripts inheriting this class
signal transition_finished


## To be overridden by transitions
func _fade() -> void:
	pass


func set_shader(path_to_shader:String=DialogicUtil.get_module_path('Background').path_join("Transitions/default_transition_shader.gdshader")) -> ShaderMaterial:
	if bg_holder:
		if path_to_shader.is_empty():
			bg_holder.material = null
			bg_holder.color = Color.TRANSPARENT
			return null
		bg_holder.material = ShaderMaterial.new()
		bg_holder.material.shader = load(path_to_shader)
		return bg_holder.material
	return null


func tween_shader_progress(_progress_parameter:="progress") -> PropertyTweener:
	if !bg_holder:
		return

	if !bg_holder.material is ShaderMaterial:
		return

	bg_holder.material.set_shader_parameter("progress", 0.0)
	var tween := create_tween()
	var tweener := tween.tween_property(bg_holder, "material:shader_parameter/progress", 1.0, time).from(0.0)
	tween.tween_callback(emit_signal.bind('transition_finished'))
	return tweener
