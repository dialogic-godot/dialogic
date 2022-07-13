extends TextureRect

class_name DialogicDisplay_Background, 'icon.png'

func _ready():
	add_to_group('dialogic_bg_image')

func _init():
	expand = true
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	anchor_right = 1
	anchor_bottom = 1
	margin_bottom = 0
	margin_left = 0
	margin_right = 0
	margin_top = 0
