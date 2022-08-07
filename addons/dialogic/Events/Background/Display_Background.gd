extends TextureRect

class_name DialogicDisplay_Background, 'icon.png'

var tween

func _ready():
	add_to_group('dialogic_bg_image')

func _init():
	ignore_texture_size = true
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	anchor_right = 1
	anchor_bottom = 1
	
	# TODO Might not be full screen when resizing window because I had to remove margin setters for godoto4

func fade_in(time = 1):
	modulate = Color(1, 1,1,0)
	tween.interpolate_property(self, "modulate",
		null, Color(1,1,1,1), time,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


func fade_out(time = 1):
	if tween:
		tween.connect('tween_all_completed', self, '_on_tween_over')
		tween.interpolate_property(self, "modulate",
			Color(1,1,1,1), Color(1,1,1,0), time,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()
	else:
		_on_tween_over()

func remove_with_delay(time =1):
	var timer = Timer.new()
	timer.timeout.connect("timeout", self, "queue_free")
	add_child(timer)
	timer.start(time+0.1)

func _on_tween_over():
	queue_free()
