extends AnimationPlayer

# A custom script/node that adds some animations to the textbox.

func _ready():
	Dialogic.Text.animation_textbox_hide.connect(_on_textbox_hide)
	Dialogic.Text.animation_textbox_show.connect(_on_textbox_show)
	Dialogic.Text.animation_textbox_new_text.connect(_on_textbox_new_text)


func _on_textbox_show():
	Dialogic.Animation.start_animating()
	%DialogicNode_DialogText.text = ""
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
