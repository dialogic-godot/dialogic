class_name DialogicPortrait
extends Node

## Default portrait class. Should be extended by custom portraits.

## Stores the character that this scene displays.
var character: DialogicCharacter
## Stores the name of the current portrait.
var portrait: String


## This function can be overridden.
## If this returns true, it won't insatnce a new scene, but call _update_portrait on this one.
## This is only relevant if the next portrait uses the same scene.
## This allows implmenting transitions between portraits that use the same scene. 
func _should_do_portrait_update(character:DialogicCharacter, portrait:String) -> bool:
	return true


## If the custom portrait accepts a change, then accept it here
## You should position your portrait so that the root node is at the pivot point*. 
## For example for a simple sprite this code would work:
## >>> $Sprite.position = $Sprite.get_rect().size * Vector2(-0.5, -1)
##
## * this depends on the portrait containers, but it will most likely be the bottom center (99% of cases)
func _update_portrait(passed_character:DialogicCharacter, passed_portrait:String) -> void:
	pass


## This should be implemented. It is used for sizing in the 
##   character editor preview and in portrait containers.
## Scale and offset will be applied by dialogic.
## For example for a simple sprite this should work:
## >>> return Rect2($Sprite.position, $Sprite.get_rect().size)
##
## This will only work as expected if the portrait is positioned so that the root is at the pivot point.
func _get_covered_rect() -> Rect2:
	return Rect2()


## If implemented, this is called when the mirror changes
func _set_mirror(mirror:bool) -> void:
	pass


## Function to accept and use the extra data, if the custom portrait wants to accept it
func _set_extra_data(data: String) -> void:
	pass


## Called when this becomes the active speaker
func _highlight() -> void:
	pass


## Called when this stops being the active speaker
func _unhighlight() -> void:
	pass
