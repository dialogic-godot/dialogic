extends TextureRect

class_name DialogicDisplay_Background, 'icon.png'

func _ready():
	add_to_group('dialogic_bg_image')

func _init():
	ignore_texture_size = true
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	anchor_right = 1
	anchor_bottom = 1
	

	
	# TODO Might not be full screen when resizing window because I had to remove margin setters for godoto4

