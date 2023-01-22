extends TextureRect

## This is the DefaultBackground scene that can simply display a image
## 
## You can create your own scenes. They can override the following methods:
##   - _update_background(@argument:String, @time:float)
##   - _fade_in(@time) (if not overriden modulate is animated)
##   - _fade_out(@time) (if not overriden modulate is animated) 
##                      make sure to free the scene at the end of the fade
##   - _should_do_background_update(@arg) -> bool


func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	anchor_right = 1
	anchor_bottom = 1

# load the new background in here. 
# The time argument is given for when [_should_do_background_update] returns true 
# (then you have to do the transition in here)
func _update_background(argument:String, time:float) -> void:
	texture = load(argument)


# if a Background event with this scene is encountered while this background is used,
# this decides whether to create a new instance and call fade_out or just call [_update_background] # on this scene. Default is false
func _should_do_background_update(argument:String) -> bool:
	return false
