class_name DialogicPortrait
extends Node

## Default portrait class. Should be extended by custom portraits.

## Stores the character that this scene displays.
var character: DialogicCharacter
## Stores the name of the current portrait.
var portrait: String

#region MAIN OVERRIDES
################################################################################

## This function can be overridden.
## If this returns true, it won't instance a new scene, but call
## [method _update_portrait] on this one.
## This is only relevant if the next portrait uses the same scene.
## This allows implementing transitions between portraits that use the same scene.
func _should_do_portrait_update(_character: DialogicCharacter, _portrait: String) -> bool:
	return false


## If the custom portrait accepts a change, then accept it here
## You should position your portrait so that the root node is at the pivot point*.
## For example for a simple sprite this code would work:
## >>> $Sprite.position = $Sprite.get_rect().size * Vector2(-0.5, -1)
##
## * this depends on the portrait containers, but it will most likely be the bottom center (99% of cases)
func _update_portrait(_passed_character: DialogicCharacter, _passed_portrait: String) -> void:
	pass


## This should be implemented. It is used for sizing in the
## character editor preview and in portrait containers.
## Scale and offset will be applied by Dialogic.
## For example, a simple sprite:
## >>> return Rect2($Sprite.position, $Sprite.get_rect().size)
##
## This will only work as expected if the portrait is positioned so that the
## root is at the pivot point.
##
## If you've used apply_texture this should work automatically.
func _get_covered_rect() -> Rect2:
	if has_meta('texture_holder_node') and get_meta('texture_holder_node', null) != null and is_instance_valid(get_meta('texture_holder_node')):
		var node: Node = get_meta('texture_holder_node')
		if node is Sprite2D or node is TextureRect:
			return Rect2(node.position, node.get_rect().size)
	return Rect2()


## If implemented, this is called when the mirror changes
func _set_mirror(mirror:bool) -> void:
	if has_meta('texture_holder_node') and get_meta('texture_holder_node', null) != null and is_instance_valid(get_meta('texture_holder_node')):
		var node: Node = get_meta('texture_holder_node')
		if node is Sprite2D or node is TextureRect:
			node.flip_h = mirror


## Function to accept and use the extra data, if the custom portrait wants to accept it
func _set_extra_data(_data: String) -> void:
	pass

#endregion

#region HIGHLIGHT OVERRIDES
################################################################################

## Called when this becomes the active speaker
func _highlight() -> void:
	pass


## Called when this stops being the active speaker
func _unhighlight() -> void:
	pass
#endregion


#region HELPERS
################################################################################

## Helper that quickly setups and checks the character and portrait.
func apply_character_and_portrait(passed_character:DialogicCharacter, passed_portrait:String) -> void:
	if passed_portrait == "" or not passed_portrait in passed_character.portraits.keys():
		passed_portrait = passed_character.default_portrait

	portrait = passed_portrait
	character = passed_character


func apply_texture(node:Node, texture_path:String) -> void:
	if not character or not character.portraits.has(portrait):
		return

	if not "texture" in node:
		return

	node.texture = null

	if not ResourceLoader.exists(texture_path):
		# This is a leftover from alpha.
		# Removing this will break any portraits made before alpha-10
		if ResourceLoader.exists(character.portraits[portrait].get('image', '')):
			texture_path = character.portraits[portrait].get('image', '')
		else:
			return

	node.texture = load(texture_path)

	if node is Sprite2D or node is TextureRect:
		if node is Sprite2D:
			node.centered = false
		node.scale = Vector2.ONE
		if node is TextureRect:
			if !is_inside_tree():
				await ready
		node.position = node.get_rect().size * Vector2(-0.5, -1)

	set_meta('texture_holder_node', node)

#endregion
