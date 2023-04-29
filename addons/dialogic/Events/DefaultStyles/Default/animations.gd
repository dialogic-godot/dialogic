extends AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready():
	Dialogic.Text.animation_textbox_hide.connect(_on_textbox_hide)
	Dialogic.Text.animation_textbox_show.connect(_on_textbox_show)
	Dialogic.Text.animation_textbox_new_text.connect(_on_textbox_new_text)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_textbox_show():
	Dialogic.Animation.start_animating()
	get_node("../DialogTextAnimationParent").modulate = Color.TRANSPARENT
	play("text_box_reveal")
	animation_finished.connect(Dialogic.Animation.animation_finished, CONNECT_ONE_SHOT)

func _on_textbox_hide():
	Dialogic.Animation.start_animating()
	play_backwards("text_box_reveal")
	animation_finished.connect(Dialogic.Animation.animation_finished, CONNECT_ONE_SHOT)

func _on_textbox_new_text():
	Dialogic.Animation.start_animating()
	play("new_text")
	animation_finished.connect(Dialogic.Animation.animation_finished, CONNECT_ONE_SHOT)
