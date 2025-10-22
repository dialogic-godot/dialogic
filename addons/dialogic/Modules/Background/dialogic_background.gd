extends Node
class_name DialogicBackground

## This is the base class for dialogic backgrounds.
## Extend it and override it's methods when you create a custom background.
## You can take a look at the default background to get an idea of how it's working.


## The subviewport container that holds this background. Set when instanced.
var viewport_container: SubViewportContainer
## The viewport that holds this background. Set when instanced.
var viewport: SubViewport


## Load the new background in here.
## The time argument is given for when [_should_do_background_update] returns true
## (then you have to do a transition in here)
func _update_background(_argument:String, _time:float) -> void:
	pass


## If a background event with this scene is encountered while this background is used,
##   this decides whether to create a new instance and call fade_out or just call [_update_background] # on this scene. Default is false
func _should_do_background_update(_argument:String) -> bool:
	return false


## Called by dialogic when first created.
## If you return false (by default) it will attempt to animate the "modulate" property.
func _custom_fade_in(_time:float) -> bool:
	return false


## Called by dialogic before removing (done by dialogic).
## If you return false (by default) it will attempt to animate the "modulate" property.
func _custom_fade_out(_time:float) -> bool:
	return false
