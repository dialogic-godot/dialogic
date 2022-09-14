extends TextureRect

## This is the DefaultBackground scene that can simply display a image
## 
## You can create your own scenes. They can override the following methods:
##   - _update_background(@argument:String)
##   - _fade_in(@time) (if not overriden modulate is animated)
##   - _fade_out(@time) (if not overriden modulate is animated)
##   - _should_do_background_update(@arg) -> bool

func _ready() -> void:
	ignore_texture_size = true
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	anchor_right = 1
	anchor_bottom = 1


func _update_background(argument:String) -> void:
	texture = load(argument)

# Return true if you want a Background event with the same scene to create a new instance
# Otherwise this scene's [_update_background] is called.
func _should_do_background_update(argument:String) -> bool:
	return false
