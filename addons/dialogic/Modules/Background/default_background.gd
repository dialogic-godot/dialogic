extends DialogicBackground

## The default background scene. 
## Extend the DialogicBackground class to create your own background scene.


func _ready() -> void:
	$Image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	$Image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	$Image.anchor_right = 1
	$Image.anchor_bottom = 1


func _update_background(argument:String, time:float) -> void:
	$Image.texture = load(argument)


func _should_do_background_update(argument:String) -> bool:
	return false
