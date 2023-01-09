@tool
class_name DialogicDefaultPortrait # TODO: Question should this have a class_name? To be extended or what?
extends Node

## Default portrait scene.

## Stores the character that this scene displays.
var character: DialogicCharacter
## Stores the name of the current portrait.
var portrait: String


## Function to accept and use the extra data, if the custom portrait wants to accept it
func _set_extra_data(data: String) -> void:
	pass


## This function can be overridden. Defaults to true, if not overridden!
func _should_do_portrait_update(character:DialogicCharacter, portrait:String) -> bool:
	return true


## If the custom portrait accepts a change, then accept it here
func _update_portrait(passed_character:DialogicCharacter, passed_portrait:String) -> void:
	if passed_portrait == "" or not passed_portrait in passed_character.portraits.keys():
		passed_portrait = passed_character['default_portrait']
	portrait = passed_portrait
	if passed_character != null:
		if character == null or character != passed_character:
			character = passed_character
		
	var path :String = character.portraits[portrait].get('image', '')
	$Portrait.texture = null
	if !path.is_empty(): $Portrait.texture = load(path)
	$Portrait.centered = false
	$Portrait.position = $Portrait.get_rect().size * Vector2(-0.5, -1)


## If implemented, this is called when the mirror changes
func _set_mirror(mirror:bool) -> void:
	$Portrait.flip_h = mirror


## If implemented, this is used by the editor for the "full view" mode
func _get_covered_rect() -> Rect2:
	if $Portrait.texture == null: 
		return Rect2()
	return Rect2($Portrait.position, $Portrait.get_rect().size)
