extends AnimationPlayer

# A custom script/node that adds some animations to the textbox.

# Careful: Sync these with the ones in the root script!
enum AnimationsIn {NONE, POP_IN, FADE_UP}
enum AnimationsOut {NONE, POP_OUT, FADE_DOWN}
enum AnimationsNewText {NONE, WIGGLE}

var animation_in : AnimationsIn
var animation_out : AnimationsOut
var animation_new_text : AnimationsNewText

var full_clear := true

func _ready():
	Dialogic.Text.animation_textbox_hide.connect(_on_textbox_hide)
	Dialogic.Text.animation_textbox_show.connect(_on_textbox_show)
	Dialogic.Text.animation_textbox_new_text.connect(_on_textbox_new_text)
	Dialogic.Text.about_to_show_text.connect(_on_about_to_show_text)


func _on_textbox_show():
	if animation_in == AnimationsIn.NONE:
		return
	play('RESET')
	Dialogic.Animation.start_animating()
	%DialogTextPanel.get_parent().modulate = Color.TRANSPARENT
	%DialogicNode_DialogText.text = ""
	match animation_in:
		AnimationsIn.POP_IN:
			play("textbox_pop")
		AnimationsIn.FADE_UP:
			play("textbox_fade_up")
	if not animation_finished.is_connected(Dialogic.Animation.animation_finished):
		animation_finished.connect(Dialogic.Animation.animation_finished, CONNECT_ONE_SHOT)


func _on_textbox_hide():
	if animation_out == AnimationsOut.NONE:
		return
	play('RESET')
	Dialogic.Animation.start_animating()
	match animation_out:
		AnimationsOut.POP_OUT:
			play_backwards("textbox_pop")
		AnimationsOut.FADE_DOWN:
			play_backwards("textbox_fade_up")
	
	if not animation_finished.is_connected(Dialogic.Animation.animation_finished):
		animation_finished.connect(Dialogic.Animation.animation_finished, CONNECT_ONE_SHOT)


func _on_about_to_show_text(info:Dictionary) -> void:
	full_clear = !info.append


func _on_textbox_new_text():
	if animation_new_text == AnimationsNewText.NONE:
		return
	
	Dialogic.Animation.start_animating()
	if full_clear:
		%DialogicNode_DialogText.text = ""
	match animation_new_text:
		AnimationsNewText.WIGGLE:
			play("new_text")
	
	if not animation_finished.is_connected(Dialogic.Animation.animation_finished):
		animation_finished.connect(Dialogic.Animation.animation_finished, CONNECT_ONE_SHOT)
