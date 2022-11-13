class_name DialogicNode_ButtonSound
extends AudioStreamPlayer

## Node that is used for playing sound effects on hover/focus/press of sibling DialogicNode_ChoiceButtons.

## Sound to be played if one of the sibling ChoiceButtons is pressed. 
## If sibling ChoiceButton has a sound_pressed set, that is prioritized.
@export var sound_pressed:AudioStream
## Sound to be played on hover. See [sound_pressed] for more.
@export var sound_hover:AudioStream
## Sound to be played on focus. See [sound_pressed] for more.
@export var sound_focus:AudioStream

func _ready():
	add_to_group('dialogic_button_sound')
	_connect_all_buttons()

#basic play sound
func play_sound(sound) -> void:
	if sound != null:
		stream = sound
		play()

func _connect_all_buttons():
	for child in get_parent().get_children():
		if child is DialogicNode_ChoiceButton:
			child.button_up.connect(_on_pressed.bind(child.sound_pressed))
			child.mouse_entered.connect(_on_hover.bind(child.sound_hover))
			child.focus_entered.connect(_on_focus.bind(child.sound_focus))


#the custom_sound argument comes from the specifec button and get used
#if none are found, it uses the above sounds

func _on_pressed(custom_sound) -> void:
	if custom_sound != null:
		play_sound(custom_sound)
	else:
		play_sound(sound_pressed)

func _on_hover(custom_sound) -> void:
	if custom_sound != null:
		play_sound(custom_sound)
	else:
		play_sound(sound_hover)

func _on_focus(custom_sound) -> void:
	if custom_sound != null:
		play_sound(custom_sound)
	else:
		play_sound(sound_focus)

