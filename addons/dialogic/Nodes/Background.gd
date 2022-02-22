extends TextureRect

var native_dialogic_background = true
var tween

func _ready():
	expand = true
	name = 'Background'
	anchor_right = 1
	anchor_bottom = 1
	if DialogicResources.get_settings_value('dialog', 'stretch_backgrounds', true):
		stretch_mode = TextureRect.STRETCH_SCALE
	else:
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	show_behind_parent = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _init():
	tween = Tween.new()
	add_child(tween)


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
	timer.connect("timeout", self, "queue_free")
	add_child(timer)
	timer.start(time+0.1)

func _on_tween_over():
	queue_free()
