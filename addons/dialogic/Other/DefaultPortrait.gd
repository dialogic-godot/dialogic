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
	

	var scale = 1
	if 'scale' in character:
		scale = character.scale
	
	if 'scale' in character.portraits[portrait]:
		$Portrait.scale = Vector2(1,1) * character.portraits[portrait].get('scale', 1) * scale
	else:
		$Portrait.scale = Vector2(1,1) * scale
	
	# Offset is for re-orienting the picutre at 1x scale, and so position in the scene needs to include the scale in the offset
	if 'offset' in character.portraits[portrait]:
		#$Portrait.position.x = character.portraits[portrait]['offset']['x'] * $Portrait.scale
		#$Portrait.position.y = character.portraits[portrait]['offset']['y'] * $Portrait.scale
		$Portrait.position = Vector2(character.portraits[portrait]['offset']['x'] * $Portrait.scale.x, 
				character.portraits[portrait]['offset']['y'] * $Portrait.scale.y)

	if character.portraits[portrait].get('mirror', false):
			$Portrait.flip_h = true

	# Set the portrait dimensions that are reported back to Dialogic. Scale is included in the math here

	portrait_width = $Portrait.texture.get_width() * $Portrait.scale.x
	portrait_height = $Portrait.texture.get_height() * $Portrait.scale.y

	
# These are from the separate Join/Update "Mirror" toggles, to override the default mirror
func does_portrait_mirror() -> bool:
	return true
	
func mirror_portrait(mirror:bool) -> void:
	if mirror:
		if character.portraits[portrait].get('mirror', false):
			$Portrait.flip_h = false
		else:
			$Portrait.flip_h = true
	else:
		if character.portraits[portrait].get('mirror', false):
			$Portrait.flip_h = true
		else:
			$Portrait.flip_h = false
			
# This function is needed on every custom portrait scene
func does_portrait_accept_extra_data() -> bool:
	return false	
	
# Function to accept and use the extra data, if the custom portrait wants to accept it
func set_portrait_extra_data(data: String) -> void:
	# This function can only receive paratmeters on an Update event, but it is called as part of Join
	# If the extra_data parameter is not set, it will call with "" string, so make sure to handle that properly
	pass
