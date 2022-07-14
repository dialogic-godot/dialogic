extends AudioStreamPlayer

class_name DialogicDisplay_ButtonSound

#all the sounds
export(AudioStream) var sound_pressed
export(AudioStream) var sound_released
export(AudioStream) var sound_hover
export(AudioStream) var sound_unhover
export(AudioStream) var sound_focus
export(AudioStream) var sound_unfocus

func _ready():
	add_to_group('dialogic_button_sound')

#basic play sound
func play_sound(sound) -> void:
	stream = sound
	play()

#the custom_sound argument comes from the specifec button and get used
#if none are found, it uses the above sounds

func _on_pressed(custom_sound) -> void:
	if custom_sound != null:
		play_sound(custom_sound)
	else:
		play_sound(sound_pressed)

func _on_released(custom_sound) -> void:
	if custom_sound != null:
		play_sound(custom_sound)
	else:
		play_sound(sound_released)

func _on_hover(custom_sound) -> void:
	if custom_sound != null:
		play_sound(custom_sound)
	else:
		play_sound(sound_hover)

func _on_unhover(custom_sound) -> void:
	if custom_sound != null:
		play_sound(custom_sound)
	else:
		play_sound(sound_unhover)

func _on_focus(custom_sound) -> void:
	if custom_sound != null:
		play_sound(custom_sound)
	else:
		play_sound(sound_focus)

func _on_unfocus(custom_sound) -> void:
	if custom_sound != null:
		play_sound(custom_sound)
	else:
		play_sound(sound_unfocus)

