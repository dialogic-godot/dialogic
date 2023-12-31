extends AnimationPlayer

## A custom script/node that adds some animations to the textbox.

# Careful: Sync these with the ones in the root script!
enum AnimationsIn {NONE, POP_IN, FADE_UP}
enum AnimationsOut {NONE, POP_OUT, FADE_DOWN}
enum AnimationsNewText {NONE, WIGGLE}

var animation_in : AnimationsIn
var animation_out : AnimationsOut
var animation_new_text : AnimationsNewText

var full_clear : bool = true

@onready var text_panel : PanelContainer = %DialogTextPanel
@onready var dialog : DialogicNode_DialogText = %DialogicNode_DialogText

func _ready() -> void:
	var text_system : DialogicSubsystemText = DialogicUtil.autoload().get(&'Text')
	var _error : int = 0
	_error = text_system.animation_textbox_hide.connect(_on_textbox_hide)
	_error = text_system.animation_textbox_show.connect(_on_textbox_show)
	_error = text_system.animation_textbox_new_text.connect(_on_textbox_new_text)
	_error = text_system.about_to_show_text.connect(_on_about_to_show_text)


func _on_textbox_show() -> void:
	if animation_in == AnimationsIn.NONE:
		return
	play('RESET')
	var animation_system : DialogicSubsystemAnimation = DialogicUtil.autoload().get(&'Animation')
	animation_system.start_animating()
	text_panel.get_parent().get_parent().set(&'modulate', Color.TRANSPARENT)
	dialog.text = ""
	match animation_in:
		AnimationsIn.POP_IN:
			play("textbox_pop")
		AnimationsIn.FADE_UP:
			play("textbox_fade_up")
	if not animation_finished.is_connected(animation_system.animation_finished):
		var _error : int = animation_finished.connect(animation_system.animation_finished, CONNECT_ONE_SHOT)


func _on_textbox_hide() -> void:
	if animation_out == AnimationsOut.NONE:
		return
	play('RESET')
	var animation_system : DialogicSubsystemAnimation = DialogicUtil.autoload().get(&'Animation')
	animation_system.start_animating()
	match animation_out:
		AnimationsOut.POP_OUT:
			play_backwards("textbox_pop")
		AnimationsOut.FADE_DOWN:
			play_backwards("textbox_fade_up")

	if not animation_finished.is_connected(animation_system.animation_finished):
		var _error : int = animation_finished.connect(animation_system.animation_finished, CONNECT_ONE_SHOT)


func _on_about_to_show_text(info:Dictionary) -> void:
	full_clear = !info.append


func _on_textbox_new_text() -> void:
	if (DialogicUtil.autoload().get(&'Input') as DialogicSubsystemInput).auto_skip.enabled:
		return

	if animation_new_text == AnimationsNewText.NONE:
		return

	var animation_system : DialogicSubsystemAnimation = DialogicUtil.autoload().get(&'Animation')
	animation_system.start_animating()
	if full_clear:
		dialog.text = ""
	match animation_new_text:
		AnimationsNewText.WIGGLE:
			play("new_text")

	if not animation_finished.is_connected(animation_system.animation_finished):
		var _error : int = animation_finished.connect(animation_system.animation_finished, CONNECT_ONE_SHOT)
