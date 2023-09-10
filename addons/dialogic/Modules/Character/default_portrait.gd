@tool
extends DialogicPortrait

## Default portrait scene.

## The parent class has a character and portrait variable. 

## If the custom portrait accepts a change, then accept it here
func _update_portrait(passed_character:DialogicCharacter, passed_portrait:String) -> void:
	if passed_portrait == "" or not passed_portrait in passed_character.portraits.keys():
		passed_portrait = passed_character.default_portrait
	
	portrait = passed_portrait
	character = passed_character
	
	if character.portraits.has(portrait):
		var path :String = character.portraits[portrait].get('image', '')
		$Portrait.texture = null
		if !path.is_empty(): $Portrait.texture = load(path)
		$Portrait.centered = false
		$Portrait.scale = Vector2.ONE
		$Portrait.position = $Portrait.get_rect().size * Vector2(-0.5, -1)


## This is called when the mirror changes
func _set_mirror(mirror:bool) -> void:
	$Portrait.flip_h = mirror


## This is used by the editor preview and portrait containers
func _get_covered_rect() -> Rect2:
	if $Portrait.texture == null:
		return Rect2()
	return Rect2($Portrait.position, $Portrait.get_rect().size)
