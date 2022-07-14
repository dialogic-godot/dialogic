extends AudioStreamPlayer

class_name DialogicDisplay_ButtonSound

#all the sounds
export(AudioStream) var sound_pressed
export(AudioStream) var sound_hover
export(AudioStream) var sound_focus

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
		if child is DialogicDisplay_ChoiceButton:
			child.connect('pressed', self, '_on_pressed', [child.sound_pressed])
			child.connect('mouse_entered', self, '_on_hover', [child.sound_hover])
			child.connect('focus_entered', self, '_on_focus', [child.sound_focus])


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

