extends Node
# Default portrait scene
# Can be extended for custom portrait scenes, this has the minimum requirements

# The following minimum features should be supported by all portrait scenes:
# @export var portrait_width: int
# @export var portrait_height: int
# func does_portrait_change() -> bool
#    If the above is returning true: func change_portrait(DialogicCharacter, String) -> void:
# func does_portrait_mirror() -> bool:
#    If the above is returning true: func mirror_portrait(mirror:bool) -> void:

class_name DialogicDefaultPortrait

@export var portrait_width: int
@export var portrait_height: int
var character: DialogicCharacter
var portrait: String

# This function is needed on every custom portrait scene
func does_portrait_change() -> bool:
	return true
	
# If the custom portrait accepts a change, then accept it here
func change_portrait(passed_character:DialogicCharacter, passed_portrait:String) -> void:
	if passed_portrait == "":
		passed_portrait = passed_character['default_portrait']
	portrait = passed_portrait
	if passed_character != null:
		if character == null || character != passed_character:
			character = passed_character
		
		
	var path = character.portraits[portrait].path
	$Portrait.texture = null
	$Portrait.texture = load(path)
	$Portrait.centered = false
	$Portrait.scale = Vector2(1,1)*character.portraits[portrait].get('scale', 1)*character.scale
	
	# Offset is for re-orienting the picutre at 1x scale, and so position in the scene needs to include the scale in the offset
	$Portrait.position.x = character.portraits[portrait]['offset']['x'] * character.portraits[portrait].scale *character.scale
	$Portrait.position.y = character.portraits[portrait]['offset']['y'] * character.portraits[portrait].scale *character.scale
	
	if character.portraits[portrait].mirror:
			$Portrait.flip_h = true

	# Set the portrait dimensions that are reported back to Dialogic. Scale is included in the math here
	portrait_width = $Portrait.texture.get_width() * character.portraits[portrait].scale * character.portraits[portrait].scale *character.scale
	portrait_height = $Portrait.texture.get_height() * character.portraits[portrait].scale * character.scale
	
# These are from the separate Join/Update "Mirror" toggles, to override the default mirror
func does_portrait_mirror() -> bool:
	return true
	
func mirror_portrait(mirror:bool) -> void:
	if mirror:
		if character.portraits[portrait].mirror:
			$Portrait.flip_h = false
		else:
			$Portrait.flip_h = true
	else:
		if character.portraits[portrait].mirror:
			$Portrait.flip_h = true
		else:
			$Portrait.flip_h = false
