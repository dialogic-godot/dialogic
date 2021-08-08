extends TextureRect

var native_dialogic_background = true
var tween

func _ready():
	expand = true
	name = 'Background'
	anchor_right = 1
	anchor_bottom = 1
	stretch_mode = TextureRect.STRETCH_SCALE
	show_behind_parent = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func create_tween():
	tween = Tween.new()
	add_child(tween)


func fade_out(time = 1):
	if tween:
		tween.connect('tween_all_completed', self, '_on_tween_over')
		tween.interpolate_property(self, "modulate",
			Color(1,1,1,1), Color(1,1,1,0), time,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()
	else:
		_on_tween_over()


func fade_in(time = 1):
	tween.interpolate_property(self, "modulate",
		Color(1,1,1,0), Color(1,1,1,1), time,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


func _on_tween_over():
	print('here')
	queue_free()
